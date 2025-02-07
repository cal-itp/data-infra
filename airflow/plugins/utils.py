import datetime
import os
from collections import defaultdict
from typing import ClassVar, Dict, List, Type, Union

import pendulum
import typer
from calitp_data_infra.storage import (
    GTFSDownloadConfig,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    fetch_all_in_partition,
)
from pydantic.v1 import validator

SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
SCHEDULE_UNZIPPED_BUCKET_HOURLY = os.environ[
    "CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED_HOURLY"
]

CALITP_BQ_LOCATION = os.environ.get("CALITP_BQ_LOCATION", "us-west2")


# TODO: this should be in calitp-data-infra maybe?
class GTFSScheduleFeedFile(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    partition_names: ClassVar[List[str]] = GTFSScheduleFeedExtract.partition_names
    ts: pendulum.DateTime
    extract_config: GTFSDownloadConfig
    original_filename: str

    # if you try to set table directly, you get an error because it "shadows a BaseModel attribute"
    # so set as a property instead
    @property
    def table(self) -> str:
        return self.filename

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def base64_url(self) -> str:
        return self.extract_config.base64_encoded_url

    @validator("ts", allow_reuse=True)
    def ts_must_be_pendulum_datetime(cls, v) -> pendulum.DateTime:
        if isinstance(v, datetime.datetime):
            v = pendulum.instance(v)
        return v


# Exists for the hourly parse transition; only difference is the bucket
class GTFSScheduleFeedFileHourly(GTFSScheduleFeedFile):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET_HOURLY


# This is currently copy-pasted into the GTFS schedule validator code
def get_schedule_files_in_hour(
    cls: Type[Union[GTFSScheduleFeedExtract, GTFSScheduleFeedFileHourly]],
    bucket: str,
    table: str,
    period: pendulum.Period,
) -> Dict[
    pendulum.DateTime, List[Union[GTFSScheduleFeedExtract, GTFSScheduleFeedFileHourly]]
]:
    # __contains__ is defined as inclusive for pendulum.Period but we want to ignore the next hour
    # see https://github.com/apache/airflow/issues/25383#issuecomment-1198975178 for data_interval_end clarification
    assert (
        period.start.replace(minute=0, second=0, microsecond=0)
        == period.end.replace(minute=0, second=0, microsecond=0)
        and period.seconds == 3600 - 1
    ), f"{period} is not exactly 1 hour exclusive of end"
    day = pendulum.instance(period.start).date()
    files: List[Union[GTFSScheduleFeedExtract, GTFSScheduleFeedFileHourly]]
    files, missing, invalid = fetch_all_in_partition(
        cls=cls,
        bucket=bucket,
        table=table,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    if missing or invalid:
        typer.secho(f"missing: {missing}")
        typer.secho(f"invalid: {invalid}")
        raise RuntimeError("found files with missing or invalid metadata; failing job")

    # Note: this is currently copy-pasted to the gtfs schedule validator
    files_in_hour = [f for f in files if f.ts in period]

    extract_map = defaultdict(list)
    for f in files_in_hour:
        extract_map[f.ts].append(f)

    typer.secho(
        f"found {len(files_in_hour)=} in {period=} ({len(extract_map.keys())} extracts)",
        fg=typer.colors.MAGENTA,
    )

    return extract_map
