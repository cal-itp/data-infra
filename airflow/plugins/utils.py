# https://pydantic-docs.helpmanual.io/usage/postponed_annotations/#self-referencing-models
from __future__ import annotations

import base64
import os
import pandas as pd
import re
import pendulum
from enum import Enum

from calitp import read_gcfs, save_to_gcfs
from pandas.errors import EmptyDataError
from pydantic import BaseModel, HttpUrl
from typing import Tuple, Optional

def make_name_bq_safe(name: str):
    """Replace non-word characters.
    See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers."""
    return str.lower(re.sub("[^\w]", "_", name))  # noqa: W605

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
        df = pd.read_csv(read_gcfs(src_path), dtype="object", **kwargs)
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


def get_successfully_downloaded_feeds(execution_date):
    """Get a list of feeds that were successfully downloaded (as noted in a
    `schedule/{execution_date}/status.csv/` file) for a given execution date.
    """
    f = read_gcfs(f"schedule/{execution_date}/status.csv")
    status = pd.read_csv(f)

    return status[lambda d: d.status == "success"]

# TODO: consider moving this to calitp-py or some other more shared location
class GTFSFeedType(str, Enum):
    schedule = "schedule"
    rt_service_alerts = "service_alerts"
    rt_trip_updates = "trip_updates"
    rt_vehicle_positions = "vehicle_positions"


class GTFSFeed(BaseModel):
    type: GTFSFeedType
    url: HttpUrl
    schedule_feed: Optional[GTFSFeed]
    auth_query_param: Optional[str]
    auth_header: Optional[str]

    @property
    def encoded_url(self) -> str:
        return base64.urlsafe_b64encode(self.url.encode())

    # ideally this would be a property
    # but how/when will datetime be populated...?
    def hive_partitions(self, datetime: pendulum.DateTime) -> Tuple[str, str, str]:
        return (
            f"dt={datetime.to_date_string()}",
            f"time={datetime.to_time_string()}",
            f"feed={self.encoded_url}",
        )

    def data_hive_path(self, bucket: str, datetime: pendulum.DateTime):
        return os.path.join(
            bucket,
            self.type,
            *self.hive_partitions(datetime),
        )
