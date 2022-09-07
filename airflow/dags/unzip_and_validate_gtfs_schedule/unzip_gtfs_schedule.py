# ---
# python_callable: airflow_unzip_extracts
# provide_context: true
# ---
import logging
import os
import pendulum
import zipfile

from io import BytesIO
from typing import ClassVar, List, Optional, Tuple
from calitp.storage import (
    fetch_all_in_partition,
    GTFSScheduleFeedExtract,
    get_fs,
    GTFSFeedType,
    PartitionedGCSArtifact,
    ProcessingOutcome,
)
from utils import GTFSScheduleFeedFile

SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
SCHEDULE_RAW_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_RAW"]


class GTFSScheduleFeedExtractUnzipOutcome(ProcessingOutcome):
    zipfile_extract_path: str
    zipfile_extract_md5hash: Optional[str]
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


def summarize_zip_contents(
    zip: zipfile.ZipFile, at: str = ""
) -> Tuple[List[str], List[str], bool]:
    files = []
    directories = []
    for entry in zip.namelist():
        if zipfile.Path(zip, at=entry).is_file():
            files.append(entry)
        if zipfile.Path(zip, at=entry).is_dir():
            directories.append(entry)
    logging.info(f"Found files: {files} and directories: {directories}")
    # the only valid case for any directory inside the zipfile is if there's exactly one and it's the only item at the root of the zipfile
    # (in which case we can treat that directory's contents as the feed)
    is_valid = (not directories) or (
        (len(directories) == 1)
        and ([item.is_dir() for item in zipfile.Path(zip, at="").iterdir()] == [True])
    )
    return files, directories, is_valid


def process_feed_files(
    fs,
    extract: GTFSScheduleFeedExtract,
    zip: zipfile.ZipFile,
    files: List[str],
    directories: List[str],
    is_valid: bool,
):
    zipfile_files = []
    if not is_valid:
        raise ValueError(
            "Unparseable zip: File/directory structure within zipfile cannot be unpacked"
        )

    for file in files:
        # make a proper path to access the .name attribute later
        file_path = zipfile.Path(zip, at=file)
        with zip.open(file) as f:
            file_content = f.read()
        file_extract = GTFSScheduleFeedFile(
            ts=extract.ts,
            base64_url=extract.base64_url,
            zipfile_path=extract.path,
            original_filename=file,
            # only replace slashes so that this is a mostly GCS-filepath-safe string
            # if we encounter something else, we will address: https://cloud.google.com/storage/docs/naming-objects
            filename=file_path.name.replace("/", "__"),
        )
        file_extract.save_content(content=file_content, fs=fs)
        zipfile_files.append(file_extract)
    return zipfile_files


def unzip_individual_feed(
    fs, extract: GTFSScheduleFeedExtract
) -> GTFSScheduleFeedExtractUnzipOutcome:
    logging.info(f"Processing {extract.name}")
    zipfile_md5_hash = ""
    files = []
    directories = []
    try:
        with fs.open(extract.path) as f:
            zipfile_md5_hash = f.info()["md5Hash"]
            zip = zipfile.ZipFile(BytesIO(f.read()))
        files, directories, is_valid = summarize_zip_contents(zip)
        zipfile_files = process_feed_files(
            fs, extract, zip, files, directories, is_valid
        )
    except Exception as e:
        logging.warn(f"Can't process {extract.path}: {e}")
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            exception=e,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    logging.info(f"Successfully unzipped {extract.path}")
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
        fs=fs,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    logging.info(f"Identified {len(extracts)} records for {day}")
    outcomes = []
    for extract in extracts:
        outcome = unzip_individual_feed(fs, extract)
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
