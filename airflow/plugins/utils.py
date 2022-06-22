import abc
import base64
import gzip
import json
import logging
import os
import re
from enum import Enum
from typing import ClassVar, List, Literal, Union
from typing import Tuple, Optional, Dict

import gcsfs
import pandas as pd
import pendulum
from airflow.models import Variable
from calitp import read_gcfs, save_to_gcfs
from calitp.config import is_development
from calitp.storage import get_fs
from pandas.errors import EmptyDataError
from pydantic import AnyUrl, validator, Field
from pydantic import BaseModel, ValidationError
from pydantic.tools import parse_obj_as
from pydantic.types import constr
from requests import Request
from typing_extensions import Annotated

GTFS_FEED_LIST_ERROR_THRESHOLD = 0.95


def make_name_bq_safe(name: str):
    """Replace non-word characters.
    See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers."""
    return str.lower(re.sub("[^\w]", "_", name))  # noqa: W605


def prefix_bucket(bucket):
    # TODO: use once we're in python 3.9+
    # bucket = bucket.removeprefix("gs://")
    bucket = bucket.replace("gs://", "")
    return f"gs://test-{bucket}" if is_development() else f"gs://{bucket}"


def partition_map(path) -> Dict[str, str]:
    return {
        key: value for key, value in re.findall(r"/(\w+)=([\w\-:]+)(?=/)", path.lower())
    }


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


# class GTFSFeedType(str, Enum):
#     schedule = "schedule"
#     rt = "rt"

# TODO: consider moving this to calitp-py or some other more shared location
class GTFSFeedType(str, Enum):
    schedule = "schedule"
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"


class DuplicateURLError(ValueError):
    pass


class AirtableGTFSDataRecord(BaseModel):
    name: str
    uri: AnyUrl
    data: GTFSFeedType
    schedule_to_use_for_rt_validation: Optional[List[str]]

    class Config:
        extra = "allow"

    @validator("data", pre=True)
    def convert_feed_type(cls, v):
        if "schedule" in v.lower():
            return GTFSFeedType.schedule
        elif "vehicle" in v.lower():
            return GTFSFeedType.vehicle_positions
        elif "trip" in v.lower():
            return GTFSFeedType.trip_updates
        elif "alerts" in v.lower():
            return GTFSFeedType.service_alerts
        return v


class GCSBaseInfo(BaseModel, abc.ABC):
    bucket: str
    name: str

    class Config:
        extra = "ignore"

    @property
    @abc.abstractmethod
    def partition(self) -> Dict[str, str]:
        pass


class GCSFileInfo(GCSBaseInfo):
    type: Literal["file"]
    size: int
    md5Hash: str

    @property
    def filename(self) -> str:
        return os.path.basename(self.name)

    @property
    def partition(self) -> Dict[str, str]:
        return partition_map(self.name)


class GCSObjectInfoList(BaseModel):
    __root__: List["GCSObjectInfo"]


class GCSDirectoryInfo(GCSBaseInfo):
    type: Literal["directory"]

    @property
    def partition(self) -> Dict[str, str]:
        return partition_map(self.name + "/")

    def children(self, fs) -> List["GCSObjectInfo"]:
        # TODO: this should work with a discriminated type but idk why it's not
        return parse_obj_as(
            GCSObjectInfoList, [fs.info(child) for child in fs.ls(self.name)]
        ).__root__


GCSObjectInfo = Annotated[
    Union[GCSFileInfo, GCSDirectoryInfo],
    Field(discriminator="type"),
]

GCSObjectInfoList.update_forward_refs()


def get_latest_file(table_path: str, keys: List[str]) -> GCSFileInfo:
    fs = get_fs()
    directory = GCSDirectoryInfo(**fs.info(table_path))

    for key in keys:
        directory = sorted(
            directory.children(fs), key=lambda o: o.partition[key], reverse=True
        )[0]

    children = directory.children(fs)
    if len(children) != 1:
        raise ValueError(
            f"found {len(directory.children(fs))} files rather than 1 in the directory {directory.name}"
        )

    ret = children[0]

    # is there a way to have pydantic check this?
    if not isinstance(ret, GCSFileInfo):
        raise ValueError(
            f"encountered unexpected type {type(ret)} rather than GCSFileInfo"
        )

    return ret


class AirtableGTFSDataExtract(BaseModel):
    records: List[AirtableGTFSDataRecord]
    timestamp: pendulum.DateTime

    # TODO: this should probably be abstracted somewhere... it's useful in lots of places, probably
    @classmethod
    def get_latest(cls) -> "AirtableGTFSDataExtract":
        latest = get_latest_file(
            "gs://test-calitp-airtable/california_transit__gtfs_datasets",
            keys=["dt", "time"],
        )

        logging.info(
            f"identified {latest.name} as the most recent extract of gtfs datasets"
        )

        with get_fs().open(latest.name, "rb") as f:
            content = gzip.decompress(f.read()).decode()

        partitions = partition_map(latest.name)
        ts = pendulum.DateTime.combine(
            pendulum.parse(partitions["dt"], exact=True),
            pendulum.parse(partitions["time"], exact=True),
        )

        records = []
        jinja_pattern = r"(?P<param_name>\w+)={{\s*(?P<param_lookup_key>\w+)\s*}}"
        # this is a bit hacky but we need this until we split off auth query params from the URI itself
        for row in content.splitlines():
            record = json.loads(row)
            if record["uri"]:
                if ".132" in record["uri"] or "GRAAS_SERVER_URL" in record["uri"]:
                    continue
                match = re.search(jinja_pattern, record["uri"])
                if match:
                    record["auth_query_param"] = {
                        match.group("param_name"): match.group("param_lookup_key")
                    }
                    record["uri"] = re.sub(jinja_pattern, "", record["uri"])
            else:
                logging.warning(
                    f"Airtable GTFS Data record missing URI: {record['gtfs_dataset_id']}"
                )
                continue
            AirtableGTFSDataRecord(**record)
            records.append(record)

        return AirtableGTFSDataExtract(timestamp=ts, records=records)


class GTFSFeed(BaseModel):
    _instances: ClassVar[Dict[str, "GTFSFeed"]] = {}
    type: GTFSFeedType
    url: AnyUrl
    # rt_type: Optional[GTFSRTFeedType]
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
        filled_auth_params = {k: auth_dict[v] for k, v in self.auth_query_param.items()}
        filled_auth_headers = {k: auth_dict[v] for k, v in self.auth_header.items()}
        # inspired by: https://stackoverflow.com/questions/18869074/create-url-without-request-execution
        return Request(
            "GET", url=self.url, params=filled_auth_params, headers=filled_auth_headers
        )


PartitionType = Union[str, int, pendulum.DateTime, pendulum.Date, pendulum.Time]


class GTFSExtract(BaseModel):
    # TODO: this should check whether the bucket exists https://stackoverflow.com/a/65628273
    bucket: constr(regex=r"gs://")  # noqa: F722
    feed: GTFSFeed
    filename: str
    response_code: int
    response_headers: Optional[Dict[str, str]]
    download_time: pendulum.DateTime

    @classmethod
    def fetch_all_in_partition(
        cls,
        fs: gcsfs.GCSFileSystem,
        bucket: str,
        feed_type: GTFSFeedType,
        partitions: Dict[str, PartitionType],
    ) -> List["GTFSExtract"]:
        path = "/".join(
            [
                bucket,
                feed_type,
                *[f"{key}={value}" for key, value in partitions.items()],
            ]
        )
        return parse_obj_as(
            List["GTFSExtract"], [fs.info(file) for file in fs.ls(path)]
        )

    @property
    def table_path(self) -> Tuple[str, str]:
        return self.bucket, self.feed.type

    @property
    def hive_partitions(self) -> Tuple[str, str, str]:
        return (
            f"dt={self.download_time.to_date_string()}",
            f"base64_url={self.feed.base64_encoded_url}",
            f"time={self.download_time.to_time_string()}",
        )

    def data_hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            self.feed.type,
            *self.hive_partitions,
            self.filename,
        )

    def save_content(self, fs: gcsfs.GCSFileSystem, bucket: str, content: bytes):
        path = self.data_hive_path(bucket)
        logging.info(f"saving {len(content)} bytes to {path}")
        fs.pipe(path=path, value=content)


class GTFSExtractOutcome(BaseModel):
    extract: GTFSExtract
    success: bool
    exception: Optional[Exception]
    body: Optional[str]

    class Config:
        arbitrary_types_allowed = True
        json_encoders = {Exception: lambda e: str(e)}

    def hive_path(self, bucket: str):
        return os.path.join(
            bucket,
            f"{self.extract.feed.type}_outcomes",
            *self.extract.hive_partitions,
            self.extract.filename,
        )


class GTFSFeedDownloadList(BaseModel):
    feeds: List[GTFSFeed]

    def get_feeds_by_type(self, type: GTFSFeedType) -> List[GTFSFeed]:
        return [feed for feed in self.feeds if feed.type == type]

    # TODO: this should return validated feeds, plus one outcome per failure so we can save them
    @staticmethod
    def from_airtable_extract(
        extract: AirtableGTFSDataExtract,
    ) -> Tuple["GTFSFeedDownloadList", List[GTFSExtractOutcome]]:
        validated_feeds: List[GTFSFeed] = []
        failures: List[GTFSExtractOutcome] = []
        for record in extract.records:
            try:
                new_feed = GTFSFeed(
                    # type=,
                    url=record.uri,
                )
                validated_feeds.append(new_feed)
            except ValidationError as e:
                failures.append(GTFSExtractOutcome())
                logging.warn(f"Error occurred for feed {record}:")
                logging.warn(e)
                continue

        success_rate = len(validated_feeds) / len(extract.records)
        if success_rate < GTFS_FEED_LIST_ERROR_THRESHOLD:
            raise RuntimeError(
                f"Success rate: {success_rate} was below error threshold: {GTFS_FEED_LIST_ERROR_THRESHOLD}"
            )
        assert len(extract.records) == len(validated_feeds) + len(failures)
        return GTFSFeedDownloadList(feeds=validated_feeds), failures


def get_auth_secret(auth_secret_key: str) -> str:
    try:
        secret = Variable.get(auth_secret_key, os.environ[auth_secret_key])
        return secret
    except KeyError as e:
        logging.error(f"No value found for {auth_secret_key}")
        raise e


if __name__ == "__main__":
    AirtableGTFSDataExtract.get_latest()
