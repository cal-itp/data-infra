import os
import pendulum

from airflow.models import BaseOperator

from calitp.storage import (
    # fetch_all_in_partition,
    # GTFSScheduleFeedExtract,
    # get_fs,
    # GTFSFeedType,
    PartitionedGCSArtifact,
    # ProcessingOutcome,
)
from typing import ClassVar, List
from utils import GTFSScheduleFeedFile

SCHEDULE_PARSED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_PARSED"]


class GTFSScheduleFeedJSONL(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_PARSED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedFile.partition_names
    ts: pendulum.DateTime
    base64_url: str
    zipfile_path: str
    input_file_path: str
    gtfs_filename: str

    # if you try to set table directly, you get an error because it "shadows a BaseModel attribute"
    # so set as a property instead
    @property
    def table(self) -> str:
        return self.gtfs_filename

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


class CsvToWarehouseOperator(BaseOperator):
    def __init__(self, date, input_table, gtfs_filename, *args, **kwargs):
        self.date = date
        self.input_table = input_table
        self.gtfs_filename = gtfs_filename

        super().__init__(*args, **kwargs)

    # def execute(self, context):
