import datetime
import os
from collections import defaultdict
from typing import ClassVar, Dict, List, Type, Union

import pandas as pd
import pendulum
import typer
from calitp_data_infra.storage import (
    GTFSDownloadConfig,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    fetch_all_in_partition,
    read_gcfs,
    save_to_gcfs,
)
from pandas.errors import EmptyDataError
from pydantic import validator

SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]

CALITP_BQ_LOCATION = os.environ.get("CALITP_BQ_LOCATION", "us-west2")


# TODO: this will be replaced during payments v2
def _keep_columns(
    src_path,
    dst_path,
    colnames,
    itp_id=None,
    url_number=None,
    extracted_at=None,
    **kwargs,
):
    """Save a CSV file with only the needed columns for a particular table.

    Args:
        src_path (string): Location of the input CSV file
        dst_path (string): Location of the output CSV file
        colnames (list): List of the colnames that should be included in output CSV
            file.
        itp_id (string, optional): itp_id to use when saving record. Defaults to None.
        url_number (string, optional): url_number to use when saving record. Defaults to
            None.
        extracted_at (string, optional): date string of extraction time. Defaults to
            None.

    Raises:
        pandas.errors.ParserError: Can be thrown when the given input file is not a
            valid CSV file. Ex: a single row could have too many columns.
    """

    # Read csv using object dtype, so pandas does not coerce data.
    # The following line of code inside the try block can throw a
    # pandas.errors.ParserError, but the responsibility to catch this error is assumed
    # to be implemented in the code that calls this method.
    try:
        df = pd.read_csv(
            read_gcfs(src_path), dtype="object", encoding_errors="replace", **kwargs
        )
    except EmptyDataError:
        # in the rare case of a totally empty data file, create a DataFrame
        # with no rows, and the target columns
        df = pd.DataFrame({k: [] for k in colnames})

    if itp_id is not None:
        df["calitp_itp_id"] = itp_id

    if url_number is not None:
        df["calitp_url_number"] = url_number

    # get specified columns, inserting NA columns where needed ----
    df_cols = set(df.columns)
    cols_present = [x for x in colnames if x in df_cols]

    df_select = df.loc[:, cols_present]

    # fill in missing columns ----
    print("DataFrame missing columns: ", set(df_select.columns) - set(colnames))

    for ii, colname in enumerate(colnames):
        if colname not in df_select:
            df_select.insert(ii, colname, pd.NA)

    if extracted_at is not None:
        df_select["calitp_extracted_at"] = extracted_at

    # save result ----
    csv_result = df_select.to_csv(index=False).encode()

    save_to_gcfs(csv_result, dst_path, use_pipe=True)


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


# This is currently copy-pasted into the GTFS schedule validator code
def get_schedule_files_in_hour(
    cls: Type[Union[GTFSScheduleFeedExtract, GTFSScheduleFeedFile]],
    bucket: str,
    table: str,
    period: pendulum.Period,
) -> Dict[pendulum.DateTime, List[PartitionedGCSArtifact]]:
    # __contains__ is defined as inclusive for pendulum.Period but we want to ignore the next hour
    # see https://github.com/apache/airflow/issues/25383#issuecomment-1198975178 for data_interval_end clarification
    assert (
        period.start.replace(minute=0, second=0, microsecond=0)
        == period.end.replace(minute=0, second=0, microsecond=0)
        and period.seconds == 3600 - 1
    ), f"{period} is not exactly 1 hour exclusive of end"
    day = pendulum.instance(period.start).date()
    files: List[Union[GTFSScheduleFeedExtract, GTFSScheduleFeedFile]]
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
