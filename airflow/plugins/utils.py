import abc
import base64
import gzip
import json
import logging
import os
import re
from enum import Enum
from typing import ClassVar, List, Union, Type, Optional, Dict, get_type_hints

import gcsfs
import humanize
import pandas as pd
import pendulum
from airflow.models import Variable
from calitp import read_gcfs, save_to_gcfs
from calitp.config import is_development
from calitp.storage import get_fs
from pandas.errors import EmptyDataError
from pydantic import AnyUrl, validator, Field
from pydantic import BaseModel
from pydantic.class_validators import root_validator
from pydantic.tools import parse_obj_as
from requests import Request
from typing_extensions import Annotated, Literal


def get_auth_secret(auth_secret_key: str) -> str:
    try:
        secret = Variable.get(auth_secret_key, os.environ[auth_secret_key])
        return secret
    except KeyError as e:
        logging.error(f"No value found for {auth_secret_key}")
        raise e


def make_name_bq_safe(name: str):
    """Replace non-word characters.
    See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers."""
    return str.lower(re.sub("[^\w]", "_", name))  # noqa: W605


def prefix_bucket(bucket):
    # TODO: use once we're in python 3.9+
    # bucket = bucket.removeprefix("gs://")
    bucket = bucket.replace("gs://", "")
    return f"gs://test-{bucket}" if is_development() else f"gs://{bucket}"


PARTITIONED_ARTIFACT_METADATA_KEY = "PARTITIONED_ARTIFACT_METADATA"

PartitionType = Union[str, int, pendulum.DateTime, pendulum.Date, pendulum.Time]

PARTITION_SERIALIZERS = {
    str: str,
    int: str,
    pendulum.DateTime: lambda dt: dt.to_iso8601_string(),
    pendulum.Date: lambda d: d.strftime("%Y-%m-%d"),
    pendulum.Time: lambda t: t.format("HH:mm:ss"),
}

PARTITION_DESERIALIZERS = {
    str: str,
    int: int,
    pendulum.DateTime: lambda s: pendulum.parse(s, exact=True),
    pendulum.Date: lambda s: pendulum.parse(s, exact=True),
    pendulum.Time: lambda s: pendulum.parse(s, exact=True),
}


def partition_map(path) -> Dict[str, PartitionType]:
    return {
        key: value
        for key, value in re.findall(r"/(\w+)=([\w\-:=]+)(?=/)", path.lower())
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


class AirtableGTFSDataRecord(BaseModel):
    name: str
    uri: Optional[str]
    data: GTFSFeedType
    schedule_to_use_for_rt_validation: Optional[List[str]]
    auth_query_param: Dict[str, str] = {}
    # TODO: add auth_headers when available in Airtable!

    class Config:
        extra = "allow"

    @validator("data", pre=True, allow_reuse=True)
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

    @property
    def schedule_url(self) -> Optional[AnyUrl]:
        # TODO: implement me
        raise NotImplementedError

    @property
    def auth_header(self) -> Dict[str, str]:
        return {}

    @property
    def base64_encoded_url(self) -> str:
        # see: https://docs.python.org/3/library/base64.html#base64.urlsafe_b64encode
        # we care about replacing slashes for GCS object names
        # can use: https://www.base64url.com/ to test encoding/decoding
        # convert in bigquery: https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions#from_base64
        return base64.urlsafe_b64encode(self.uri.encode()).decode()

    def build_request(self, auth_dict: dict) -> Request:
        filled_auth_params = {k: auth_dict[v] for k, v in self.auth_query_param.items()}
        filled_auth_headers = {k: auth_dict[v] for k, v in self.auth_header.items()}
        # inspired by: https://stackoverflow.com/questions/18869074/create-url-without-request-execution
        return Request(
            "GET", url=self.uri, params=filled_auth_params, headers=filled_auth_headers
        )


class PartitionedGCSArtifact(BaseModel, abc.ABC):
    """
    This class is designed to be subclassed to model "extracts", i.e. a particular
    download of a given data source.
    """

    filename: str

    class Config:
        json_encoders = {
            pendulum.DateTime: lambda dt: dt.to_iso8601_string(),
        }

    @property
    @abc.abstractmethod
    def bucket(self) -> str:
        """Bucket name"""

    @property
    @abc.abstractmethod
    def table(self) -> str:
        """Table name"""

    @classmethod
    def bucket_table(cls) -> str:
        bucket = cls.bucket.replace("gs://", "")
        return f"gs://{bucket}/{cls.table}/"

    @property
    @abc.abstractmethod
    def partition_names(self) -> List[str]:
        """
        Defines the partitions into which this artifact is organized.
        The order does matter!
        """

    @property
    def partition_types(self) -> Dict[str, Type[PartitionType]]:
        return {}

    @root_validator(allow_reuse=True)
    def check_partitions(cls, values):
        cls_properties = [
            name for name in dir(cls) if isinstance(getattr(cls, name), property)
        ]
        missing = [
            name
            for name in cls.partition_names
            if name not in values and name not in cls_properties
        ]
        if missing:
            raise ValueError(
                f"all partition names must exist as fields or properties; missing {missing}"
            )
        return values

    @property
    def path(self):
        return os.path.join(
            self.bucket,
            self.table,
            *[
                f"{name}={PARTITION_SERIALIZERS[type(getattr(self, name))](getattr(self, name))}"
                for name in self.partition_names
            ],
            self.filename,
        )

    def save_content(self, fs: gcsfs.GCSFileSystem, content: bytes):
        logging.info(f"saving {humanize.naturalsize(len(content))} to {self.path}")
        fs.pipe(path=self.path, value=content)
        fs.setxattrs(
            path=self.path,
            # This syntax seems silly but it's so we pass the _value_ of PARTITIONED_ARTIFACT_METADATA_KEY
            **{PARTITIONED_ARTIFACT_METADATA_KEY: self.json()},
        )


def fetch_all_in_partition(
    cls: Type[PartitionedGCSArtifact],
    fs: gcsfs.GCSFileSystem,
    bucket: str,
    table: str,
    partitions: Dict[str, PartitionType],
) -> List[Type[PartitionedGCSArtifact]]:
    path = "/".join(
        [
            bucket,
            table,
            *[f"{key}={value}" for key, value in partitions.items()],
        ]
    )
    files = parse_obj_as(
        GCSObjectInfoList,
        [v for _, _, files in list(fs.walk(path, detail=True)) for v in files.values()],
    )
    return [
        parse_obj_as(
            cls, json.loads(fs.getxattr(file.name, PARTITIONED_ARTIFACT_METADATA_KEY))
        )
        for file in files.__root__
    ]


class ProcessingOutcome(BaseModel, abc.ABC):
    success: bool
    exception: Optional[Exception]
    input_record: BaseModel

    class Config:
        arbitrary_types_allowed = True
        json_encoders = {Exception: lambda e: str(e)}

    # TODO: is this really useful?
    @property
    @abc.abstractmethod
    def input_type(self) -> Type[PartitionedGCSArtifact]:
        """The input type that was processed to produce this outcome."""


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


# TODO: we could probably pass this a class
def get_latest_file(
    table_path: str, partitions: Dict[str, Type[PartitionType]]
) -> GCSFileInfo:
    fs = get_fs()
    directory = GCSDirectoryInfo(**fs.info(table_path))

    for key, typ in partitions.items():
        directory = sorted(
            directory.children(fs),
            key=lambda o: PARTITION_DESERIALIZERS[typ](o.partition[key]),
            reverse=True,
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


class AirtableGTFSDataExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = prefix_bucket("gs://calitp-airtable")
    table: ClassVar[str] = "california_transit__gtfs_datasets"
    partition_names: ClassVar[List[str]] = ["dt", "time"]
    dt: pendulum.Date
    time: pendulum.Time
    records: List[AirtableGTFSDataRecord]

    # TODO: this should probably be abstracted somewhere... it's useful in lots of places, probably
    @classmethod
    def get_latest(cls) -> "AirtableGTFSDataExtract":
        # TODO: this concatenation should live on the abstract base class probably
        latest = get_latest_file(
            cls.bucket_table(),
            partitions={
                name: get_type_hints(cls).get(name, str) for name in cls.partition_names
            },
        )

        logging.info(
            f"identified {latest.name} as the most recent extract of gtfs datasets"
        )

        with get_fs().open(latest.name, "rb") as f:
            content = gzip.decompress(f.read()).decode()

        records = [
            AirtableGTFSDataRecord(**json.loads(row)) for row in content.splitlines()
        ]

        return AirtableGTFSDataExtract(
            records=records,
            filename=latest.filename,
            dt=pendulum.parse(latest.partition["dt"], exact=True),
            time=pendulum.parse(latest.partition["time"], exact=True),
        )


class GTFSFeedExtractInfo(PartitionedGCSArtifact):
    # TODO: this should check whether the bucket exists https://stackoverflow.com/a/65628273
    # TODO: this should be named `gtfs-raw` _or_ we make it dynamic
    bucket: ClassVar[str] = prefix_bucket("gs://calitp-gtfs-raw")
    partition_names: ClassVar[List[str]] = ["dt", "base64_url", "time"]
    config: AirtableGTFSDataRecord
    response_code: int
    response_headers: Optional[Dict[str, str]]
    download_time: pendulum.DateTime

    @property
    def table(self) -> GTFSFeedType:
        return self.config.data

    @property
    def dt(self) -> pendulum.Date:
        return self.download_time.date()

    @property
    def base64_url(self) -> str:
        return self.config.base64_encoded_url

    @property
    def time(self) -> pendulum.Time:
        return self.download_time.time()


class AirtableGTFSDataRecordProcessingOutcome(ProcessingOutcome):
    input_type: ClassVar[Type[PartitionedGCSArtifact]] = GTFSFeedExtractInfo
    extract: Optional[GTFSFeedExtractInfo]


# class GTFSDownloadFeeds(PartitionedGCSArtifact):
#     __root__: List[AirtableGTFSDataRecordProcessingOutcome]
#     bucket: ClassVar[str] = prefix_bucket("gs://calitp-gtfs-raw")
#     table: ClassVar[str] =
#     partition_names: ClassVar[List[str]] = ["dt", "base64_url", "time"]

# class GTFSFeedExtractOutcome(PartitionedGCSArtifact):
#     extract: Optional[GTFSFeedExtract]
#     success: bool
#     exception: Optional[Exception]
#     body: Optional[str]
#
#     class Config:
#         arbitrary_types_allowed = True
#         json_encoders = {Exception: lambda e: str(e)}
#
#     @property
#     def table(self) -> str:
#         return f"{self.extract.feed.type}_outcomes"
#
#     @property
#     def bucket(self) -> str:
#         pass


if __name__ == "__main__":
    print(
        get_latest_file(
            table_path="gs://rt-parsed/service_alerts/",
            partitions={
                "dt": pendulum.Date,
                "itp_id": int,
                "url_number": int,
                "hour": int,
            },
        )
    )
    records = AirtableGTFSDataExtract.get_latest().records
    extract = GTFSFeedExtractInfo(
        filename="whatever",
        config=records[0],
        response_code=200,
        response_headers={},
        download_time=pendulum.now(),
    )
    # extract.save_content(get_fs(), b"")
    # print(
    #     AirtableGTFSDataRecordProcessingOutcome(
    #         success=True,
    #         extract=extract,
    #     ).json(indent=4)
    # )
    objs = fetch_all_in_partition(
        cls=GTFSFeedExtractInfo,
        fs=get_fs(),
        bucket=GTFSFeedExtractInfo.bucket,
        table=GTFSFeedType.schedule.value,
        partitions=dict(
            dt=pendulum.Date(year=2022, month=6, day=24),
        ),
    )
    print(f"found {len(objs)} objects in partition")
