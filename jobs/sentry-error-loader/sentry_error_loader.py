import gzip
import os
from datetime import datetime
from typing import ClassVar, List, Optional

import clickhouse_connect  # type: ignore
import pandas as pd
import pendulum
import typer
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)

CALITP_BUCKET__SENTRY_EVENTS = os.environ["CALITP_BUCKET__SENTRY_EVENTS"]


def process_arrays_for_nulls(arr):
    """
    BigQuery doesn't allow arrays that contain null values --
    see: https://cloud.google.com/bigquery/docs/reference/standard-sql/data-types#array_nulls
    Therefore we need to manually replace nulls with falsy values according
    to the type of data we find in the array.
    """
    types = set(type(entry) for entry in arr if entry is not None)

    if not types:
        return []
    # use empty string for all non-numeric types
    # may need to expand this over time
    filler = -1 if types <= {int, float} else ""
    return [x if x is not pd.NA else filler for x in arr]


def fetch_and_clean_from_clickhouse(project_slug, target_date):
    """
    Download Sentry event records from Clickhouse as a DataFrame.
    """

    print(f"Gathering Sentry event data for project {project_slug}")

    extract = SentryExtract(
        project_slug=project_slug,
        dt=target_date,
        execution_ts=pendulum.now(),
        filename="events.jsonl.gz",
    )

    client = clickhouse_connect.get_client(
        host="sentry-clickhouse.sentry.svc.cluster.local", port=8123
    )
    all_rows = client.query_df(
        f"""SELECT * FROM errors_dist
                                   WHERE toDate(timestamp) == '{target_date}'"""
    )

    cleaned_df = all_rows.rename(make_name_bq_safe, axis="columns")

    cols_with_nulls_in_arrays = ["exception_frames_colno", "exception_frames_package"]
    for col_name in cols_with_nulls_in_arrays:
        cleaned_df[col_name] = cleaned_df[col_name].apply(process_arrays_for_nulls)

    """
    Pandas' default timestamp datatype returned by clickhouse-connect writes out unix timestamps
    in nanoseconds, but they get interpreted by BQ as microseconds. A quick cast to datetime string
    before writing avoids triggering the issue.
    """
    cols_with_unix_timestamps = ["timestamp", "message_timestamp", "received"]
    for col_name in cols_with_unix_timestamps:
        cleaned_df[col_name] = cleaned_df[col_name].apply(str)

    extract.data = cleaned_df

    return extract


class SentryExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__SENTRY_EVENTS
    table: ClassVar[str] = "events"
    dt: pendulum.Date
    execution_ts: pendulum.DateTime
    partition_names: ClassVar[List[str]] = ["project_slug", "dt", "execution_ts"]
    project_slug: str
    data: Optional[pd.DataFrame]

    class Config:
        arbitrary_types_allowed = True

    def save_to_gcs(self, fs):
        self.save_content(
            fs=fs,
            content=gzip.compress(
                self.data.to_json(
                    orient="records", lines=True, default_handler=str
                ).encode()
            ),
            exclude={"data"},
        )


def main(
    project_slug: str,
    logical_date: datetime = typer.Argument(
        ...,
        help="The date on which the targeted error(s) occurred.",
        formats=["%Y-%m-%d"],
    ),
):
    target_date = pendulum.instance(logical_date).date()
    extract = fetch_and_clean_from_clickhouse(project_slug, target_date)
    fs = get_fs()
    return extract.save_to_gcs(fs=fs)


if __name__ == "__main__":
    typer.run(main)
