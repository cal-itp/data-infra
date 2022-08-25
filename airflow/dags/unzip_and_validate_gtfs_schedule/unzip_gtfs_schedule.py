# ---
# python_callable: airflow_unzip_extracts
# provide_context: true
# ---
import logging
import os
import pendulum
import zipfile

from typing import ClassVar, List, Optional

from calitp.storage import (
    fetch_all_in_partition,
    GTFSScheduleFeedExtract,
    get_fs,
    GTFSFeedType,
    PartitionedGCSArtifact,
    ProcessingOutcome,
)

SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
SCHEDULE_RAW_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_RAW"]


class GTFSScheduleFeedFile(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedExtract.partition_names
    ts: pendulum.DateTime
    base64_url: str
    zipfile_path: str
    original_filename: str

    # if you try to set table directly, you get an error because it "shadows a BaseModel attribute"
    # so set as a property instead
    @property
    def table(self) -> str:
        # only replace slashes so that this is a mostly GCS-filepath-safe string
        # if we encounter something else, we will address: https://cloud.google.com/storage/docs/naming-objects
        return self.original_filename.replace("/", "__")

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


class GTFSScheduleFeedExtractUnzipOutcome(ProcessingOutcome):
    zipfile_extract_path: str
    zipfile_extract_md5hash: str
    zipfile_files: Optional[List[str]]
    zipfile_dirs: Optional[List[str]]
    extracted_files: Optional[List[str]]


class ScheduleUnzipResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    table: ClassVar[str] = "unzipping_results"
    partition_names: ClassVar[List[str]] = ["dt"]
    dt: pendulum.Date
    outcomes: List[GTFSScheduleFeedExtractUnzipOutcome]

    @property
    def successes(self) -> List[GTFSScheduleFeedExtractUnzipOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

    @property
    def failures(self) -> List[GTFSScheduleFeedExtractUnzipOutcome]:
        return [outcome for outcome in self.outcomes if not outcome.success]

    def save(self, fs):
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
            exclude={"outcomes"},
        )


def summarize_zip_contents(zip: zipfile.ZipFile, at: str = ""):
    files = []
    directories = []
    for entry in zip.namelist():
        if zipfile.Path(zip, at=entry).is_file():
            files.append(entry)
        if zipfile.Path(zip, at=entry).is_dir():
            directories.append(entry)
    return files, directories


def process_feed_files(fs, extract, feed_directory: str = ""):
    zipfile_files = []
    with fs.open(extract.path) as f:
        zip = zipfile.ZipFile(f)
        for file in zipfile.Path(zip, at=feed_directory).iterdir():
            if feed_directory:
                file_name = os.path.join(feed_directory, file.name)
            else:
                file_name = file.name
            with zip.open(file_name) as f:
                file_content = f.read()
            file_extract = GTFSScheduleFeedFile(
                ts=extract.ts,
                base64_url=extract.base64_url,
                zipfile_path=extract.path,
                original_filename=file.name,
                # TODO: do we need to make this safe?
                filename=file.name,
            )
            file_extract.save_content(content=file_content, fs=fs)
            zipfile_files.append(file_extract)
    return zipfile_files


def unzip_individual_feed(
    fs, extract: GTFSScheduleFeedExtract
) -> GTFSScheduleFeedExtractUnzipOutcome:
    """If zip contains a directory and nothing else at top level or files at top level,
    we return the contents of the top level or the unique directory as the feed.
    If there's a directory *and* other files at top level within zip, or if
    there are nested directories, say we can't parse."""

    logging.info(f"Processing {extract.name}")
    zipfile_md5_hash = ""
    try:
        with fs.open(extract.path) as f:
            zipfile_md5_hash = f.info()["md5Hash"]
            zip = zipfile.ZipFile(f)
        files, directories = summarize_zip_contents(zip)
        logging.info(f"Found files: {files} and directories: {directories}")
    except Exception as e:
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            exception=e,
        )
    # more than one directory --> invalid zip
    if len(directories) > 1:
        logging.info(f"Invalid zip {extract.path}: Multiple directories found")
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    # mix of directories and files at top level --> invalid zip
    elif (
        len(directories) > 0
        and len([item for item in zipfile.Path(zip, at="").iterdir()]) > 1
    ):
        logging.info(f"Invalid zip {extract.path}: Mix of directories and files found")
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    # if the only item in the zipfile is a directory at the root level
    # we can treat the contents of that directory as if they were the feed
    elif [item.is_dir() for item in zipfile.Path(zip, at="").iterdir()] == [True]:
        logging.info(f"Valid zip {extract.path}: One toplevel directory found")
        feed_directory = directories[0]
        zipfile_files = process_feed_files(fs, extract, feed_directory)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=True,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            zipfile_files=files,
            zipfile_dirs=directories,
            extracted_files=[file.path for file in zipfile_files],
        )
    else:
        logging.info(f"Valid zip {extract.path}")
        zipfile_files = process_feed_files(fs, extract)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=True,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            zipfile_files=files,
            zipfile_dirs=directories,
            extracted_files=[file.path for file in zipfile_files],
        )


def unzip_extracts(day: pendulum.datetime):
    fs = get_fs()

    day = pendulum.instance(day).date()
    extracts = fetch_all_in_partition(
        cls=GTFSScheduleFeedExtract,
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        fs=get_fs(),
        partitions={
            "dt": day,
        },
        verbose=True,
    )
    logging.info(f"Identified {len(extracts)} records for {day}")
    outcomes = []
    for extract in extracts:
        outcome = unzip_individual_feed(fs, extract)
        logging.info(f"Processing success: {outcome.success}")
        outcomes.append(outcome)

    result = ScheduleUnzipResult(filename="results.jsonl", dt=day, outcomes=outcomes)
    result.save(fs)

    assert len(extracts) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"


def airflow_unzip_extracts(task_instance, execution_date, **kwargs):
    unzip_extracts(execution_date)


if __name__ == "__main__":
    # for testing
    logging.basicConfig(level=logging.INFO)
    unzip_extracts(pendulum.datetime(1901, 1, 1))
