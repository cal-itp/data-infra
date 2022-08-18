# ---
# python_callable: unzip
# provide_context: true
# ---
import os
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

SCHEDULE_UNZIPPED_BUCKET = os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED")


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


def summarize_zip(zip: zipfile.ZipFile, at: str = ""):
    # check for directories
    type_map = {True: "directory", False: "file"}
    return {
        item.name: type_map(item.is_dir())
        for item in zipfile.Path(root=zip, at=at).iterdir()
    }


def unzip_individual_feed(zip: zipfile.ZipFile):
    """If zip contains a directory and nothing else at top level or files at top level,
    we return the contents of the top level or the unique directory as the feed.
    If there's a directory *and* other files at top level within zip, or if
    there are nested directories, say we can't parse."""

    top_level_objects = summarize_zip(zip)

    if "directory" in top_level_objects.values():
        # can only process directory if it's the only item in the zip
        if len(top_level_objects) != 1:
            return GTFSScheduleFeedExtractUnzipOutcome(
                success=False,
                contained_directory=True,
            )
    # TODO: finish implementing
    # need to check for nested directories -- at which point we say unzipping failed
    # if there is exactly one top level directory, we return an indicator of such
    # decide return structure

    return top_level_objects


def unzip_extracts(day=pendulum.today()):
    fs = get_fs()

    day = pendulum.instance(day).date()
    extracts = fetch_all_in_partition(
        cls=GTFSFeedExtractInfo,
        table=GTFSFeedType.schedule,
        fs=get_fs(),
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    outcomes = []
    for extract in extracts[0:1]:
        try:
            with fs.open(extract.path) as f:
                zip = zipfile.ZipFile(f)
            # print(zip.infolist())
            item_check = unzip_individual_feed(zip)
            print(item_check)
        except Exception as e:
            outcomes.append(
                GTFSScheduleFeedExtractUnzipOutcome(
                    success=False,
                    extract=extract,
                    exception=e,
                )
            )
