import base64
import os
import pandas as pd
import re
import pendulum
from enum import Enum
from requests import Request
import logging

from airflow.models import Variable
from calitp import read_gcfs, save_to_gcfs
from pandas.errors import EmptyDataError
from pydantic import AnyUrl, BaseModel, ValidationError, validator
from typing import ClassVar, Dict, List, Tuple, Optional

GTFS_FEED_LIST_ERROR_THRESHOLD = 0.95

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
    rt = "rt"


class GTFSRTFeedType(str, Enum):
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"


class DuplicateURLError(ValueError):
    pass


class GTFSFeed(BaseModel):
    _instances: ClassVar[Dict[str, "GTFSFeed"]] = {}
    type: GTFSFeedType
    url: AnyUrl
    rt_type: Optional[GTFSRTFeedType]
    schedule_url: Optional[AnyUrl]
    # for both auth dicts, key is auth param name in URL (like "api_key"),
    # value is name of secret (Airflow or environment variable)
    # where API key is stored (like AGENCY_NAME_API_KEY)
    auth_query_param: Optional[Dict[str, str]]
    auth_header: Optional[Dict[str, str]]

    def __init__(self, **kwargs):
        super(GTFSFeed, self).__init__(**kwargs)
        self._instances[self.url] = self

    @property
    def schedule_feed(self):
        return self._instances[self.schedule_url]

    @property
    def base64_encoded_url(self) -> str:
        # see: https://docs.python.org/3/library/base64.html#base64.urlsafe_b64encode
        # we care about replacing slashes for GCS object names
        # can use: https://www.base64url.com/ to test encoding/decoding
        # convert in bigquery: https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions#from_base64
        return base64.urlsafe_b64encode(self.url.encode()).decode()

    @validator("url", allow_reuse=True)
    def urls_must_be_unique(cls, v):
        if v in cls._instances:
            raise DuplicateURLError(v)
        return v

    # @validator
    # def rt_type_defined(self):
    #     assert

    def build_request(self, auth_dict: dict) -> Request:
        filled_auth_params = {k: auth_dict(v) for k, v in self.auth_query_param.items()}
        filled_auth_headers = {k: auth_dict(v) for k, v in self.auth_header.items()}
        # inspired by: https://stackoverflow.com/questions/18869074/create-url-without-request-execution
        return Request(
            "GET", url=self.url, params=filled_auth_params, headers=filled_auth_headers
        )


class GTFSExtract(BaseModel):
    feed: GTFSFeed
    download_time: pendulum.DateTime

    @property
    def hive_partitions(self) -> Tuple[str, str, str]:
        return (
            f"dt={self.download_time.to_date_string()}",
            f"base64_url={self.feed.encoded_url}",
            f"time={self.download_time.to_time_string()}",
        )

    def data_hive_path(self, bucket: str):
        return os.path.join(bucket, self.feed.type, *self.hive_partitions())


class GTFSFeedDownloadList(BaseModel):
    feeds: List[GTFSFeed]

    def get_feeds_by_type(self, type: GTFSFeedType) -> List[GTFSFeed]:
        return [feed for feed in self.feeds if feed.type == type]

    @staticmethod
    def from_dict(feed_dicts: List[Dict]):
        validated_feeds = []
        failures = []
        for feed in feed_dicts:
            try:
                new_feed = GTFSFeed(**feed)
                validated_feeds.append(new_feed)
            except ValidationError as e:
                failures.append(feed)
                logging.warn(f"Error occurred for feed {feed}:")
                logging.warn(e)
                continue

        success_rate = len(validated_feeds) / len(feed_dicts)
        if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
            raise RuntimeError(
                f"Success rate: {success_rate} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"
            )
        return GTFSFeedDownloadList(feeds=validated_feeds), failures


def get_auth_secret(auth_secret_key: str) -> str:
    try:
        secret = Variable.get(auth_secret_key, os.environ[auth_secret_key])
        return secret
    except KeyError as e:
        logging.error(f"No value found for {auth_secret_key}")
        raise e
