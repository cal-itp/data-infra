# ---
# python_callable: unzip
# provide_context: true
# ---
import os
import logging
import pendulum
import zipfile

from typing import ClassVar, List, Optional
from pydantic import Field

from calitp.storage import (
    fetch_all_in_partition,
    GTFSFeedExtractInfo,
    get_fs,
    GTFSFeedType,
    PartitionedGCSArtifact,
    ProcessingOutcome,
)

# TODO: what level?
logging.basicConfig(format="%(levelname)s:%(message)s", level=logging.INFO)

# SCHEDULE_UNZIPPED_BUCKET = os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED")
# SCHEDULE_RAW_BUCKET = os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW")
# for testing:
SCHEDULE_RAW_BUCKET = "test-calitp-gtfs-schedule-raw"
SCHEDULE_UNZIPPED_BUCKET = "test-calitp-gtfs-schedule-unzipped"


class GTFSScheduleFeedFile(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    partition_names: ClassVar[List[str]] = ["dt", "base64_url", "ts"]
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
    extract: GTFSFeedExtractInfo = Field(..., exclude={"config"})
    zipfile_files: Optional[List[str]]
    zipfile_dirs: Optional[List[str]]
    extracted_files: Optional[List[GTFSScheduleFeedFile]]


class ScheduleUnzipResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    table: ClassVar[str] = "unzipping_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    dt: pendulum.Date
    ts: pendulum.DateTime
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


def process_feed_files(fs, extract_path, extract, feed_directory: str = ""):
    zipfile_files = []
    with fs.open(extract_path) as f:
        zip = zipfile.ZipFile(f)
        for file in zipfile.Path(zip, at=feed_directory).iterdir():
            with zip.open(file.name) as f:
                file_content = f.read()
            file_extract = GTFSScheduleFeedFile(
                ts=extract.ts,
                base64_url=extract.base64_url,
                zipfile_path=extract_path,
                original_filename=file.name,
                # TODO: do we need to make this safe?
                filename=file.name,
            )
            file_extract.save_content(content=file_content, fs=fs)
            zipfile_files.append(file_extract)
    return zipfile_files


def unzip_individual_feed(
    fs, extract: GTFSFeedExtractInfo
) -> GTFSScheduleFeedExtractUnzipOutcome:
    """If zip contains a directory and nothing else at top level or files at top level,
    we return the contents of the top level or the unique directory as the feed.
    If there's a directory *and* other files at top level within zip, or if
    there are nested directories, say we can't parse."""

    # TODO: figure out why this isn't working? should be accessible via just extract.path
    # need to update all refs once it's working again
    extract_path = os.path.join(SCHEDULE_RAW_BUCKET, extract.name)
    logging.info(f"Processing {extract.name}")
    try:
        with fs.open(extract_path) as f:
            zip = zipfile.ZipFile(f)
        files, directories = summarize_zip_contents(zip)
        logging.info(f"Found: {files} and {directories}")
    except Exception as e:
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            extract=extract,
            exception=e,
        )
    # more than one directory --> invalid zip
    if len(directories) > 1:
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            extract=extract,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    # if the only item in the zipfile is a directory at the root level
    # we can treat the contents of that directory as if they were the feed
    elif [item.is_dir() for item in zipfile.Path(zip, at="").iterdir()] == [True]:
        feed_directory = directories[0]
        zipfile_files = process_feed_files(fs, extract_path, extract, feed_directory)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=True,
            extract=extract,
            zipfile_files=files,
            zipfile_dirs=directories,
            extracted_files=zipfile_files,
        )
    else:
        zipfile_files = zipfile_files = process_feed_files(fs, extract_path, extract)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=True,
            extract=extract,
            zipfile_files=files,
            zipfile_dirs=directories,
            extracted_files=zipfile_files,
        )


def unzip_extracts(day=pendulum.today()):
    fs = get_fs()

    day = pendulum.instance(day).date()
    extracts = fetch_all_in_partition(
        cls=GTFSFeedExtractInfo,
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
    # TODO: extract all not just first one
    for extract in extracts[0:1]:
        outcome = unzip_individual_feed(fs, extract)
        logging.info(f"Outcome: {outcome}")
        outcomes.append(outcome)

        # TODO: actually save out outcomes file
