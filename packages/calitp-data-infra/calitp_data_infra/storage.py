import abc
import base64
import cgi
import gzip
import json
import logging
import os
import re
import sys
from abc import ABC
from datetime import datetime
from enum import Enum
from typing import (
    Callable,
    ClassVar,
    Dict,
    List,
    Mapping,
    Optional,
    Tuple,
    Type,
    Union,
    get_type_hints,
)

import backoff
import gcsfs  # type: ignore
import humanize
import pendulum
from google.cloud import storage  # type: ignore
from pydantic import (
    BaseModel,
    ConstrainedStr,
    Extra,
    Field,
    HttpUrl,
    ValidationError,
    validator,
)
from pydantic.class_validators import root_validator
from pydantic.tools import parse_obj_as
from requests import Request, Session
from typing_extensions import Annotated, Literal

JSONL_EXTENSION = ".jsonl"
JSONL_GZIP_EXTENSION = f"{JSONL_EXTENSION}.gz"


def get_fs(gcs_project="", **kwargs):
    if os.environ.get("CALITP_AUTH") == "cloud":
        return gcsfs.GCSFileSystem(project=gcs_project, token="cloud", **kwargs)
    else:
        return gcsfs.GCSFileSystem(
            project=gcs_project, token="google_default", **kwargs
        )


def make_name_bq_safe(name: str):
    """Replace non-word characters.
    See: https://cloud.google.com/bigquery/docs/reference/standard-sql/lexical#identifiers.
    Add underscore if starts with a number.  Also sometimes excel has columns names that are
    all numbers, not even strings of numbers (ﾉﾟ0ﾟ)ﾉ~
    """
    if type(name) != str:
        name = str(name)
    if name[:1].isdigit():
        name = "_" + name
    return str.lower(re.sub("[^\w]", "_", name))  # noqa: W605


AIRTABLE_BUCKET = os.getenv("CALITP_BUCKET__AIRTABLE")
GTFS_DOWNLOAD_CONFIG_BUCKET = os.getenv("CALITP_BUCKET__GTFS_DOWNLOAD_CONFIG")
SCHEDULE_RAW_BUCKET = os.getenv("CALITP_BUCKET__GTFS_SCHEDULE_RAW")
RT_RAW_BUCKET = os.getenv("CALITP_BUCKET__GTFS_RT_RAW")


PARTITIONED_ARTIFACT_METADATA_KEY = "PARTITIONED_ARTIFACT_METADATA"

PartitionType = Union[str, int, pendulum.DateTime, pendulum.Date, pendulum.Time]

PARTITION_SERIALIZERS: Dict[Type, Callable] = {
    str: str,
    int: str,
    pendulum.Date: lambda d: d.to_date_string(),
    pendulum.DateTime: lambda dt: dt.to_iso8601_string(),
}

PARTITION_DESERIALIZERS: Dict[Type, Callable] = {
    str: str,
    int: int,
    pendulum.Date: lambda s: pendulum.parse(s, exact=True),
    pendulum.DateTime: lambda s: pendulum.parse(s, exact=True),
}


def partition_map(path) -> Dict[str, str]:
    return {key: value for key, value in re.findall(r"/(\w+)=([\w\-:=+.]+)(?=/)", path)}


def serialize_partitions(partitions: Dict[str, PartitionType]) -> List[str]:
    return [
        f"{name}={PARTITION_SERIALIZERS[type(value)](value)}"
        for name, value in partitions.items()
    ]


class GTFSFeedType(str, Enum):
    schedule = "schedule"
    service_alerts = "service_alerts"
    trip_updates = "trip_updates"
    vehicle_positions = "vehicle_positions"

    @property
    def is_rt(self) -> bool:
        if self == GTFSFeedType.schedule:
            return False
        if self in (
            GTFSFeedType.service_alerts,
            GTFSFeedType.trip_updates,
            GTFSFeedType.vehicle_positions,
        ):
            return True
        raise RuntimeError(f"managed to end up with an invalid enum type of {self}")


def upload_from_string(
    blob: storage.Blob, data: bytes, content_type: str, client: storage.Client
):
    blob.upload_from_string(
        data=data,
        content_type=content_type,
        client=client,
    )


# Is there a better pattern for making this retry optional by the caller?
@backoff.on_exception(
    backoff.expo,
    base=5,
    exception=(Exception,),
    max_tries=3,
)
def upload_from_string_with_retry(*args, **kwargs):
    return upload_from_string(*args, **kwargs)


def set_metadata(blob: storage.Blob, model: BaseModel, exclude=None):
    blob.metadata = {PARTITIONED_ARTIFACT_METADATA_KEY: model.json(exclude=exclude)}
    blob.patch()


# Is there a better pattern for making this retry optional by the caller?
@backoff.on_exception(
    backoff.expo,
    base=5,
    exception=(Exception,),
    max_tries=3,
)
def set_metadata_with_retry(*args, **kwargs):
    return set_metadata(*args, **kwargs)


class StringNoWhitespace(ConstrainedStr):
    strip_whitespace = True


class PartitionedGCSArtifact(BaseModel, abc.ABC):
    """
    This class is designed to be subclassed to model "extracts", i.e. a particular
    download of a given data source.
    """

    filename: StringNoWhitespace

    class Config:
        json_encoders = {
            pendulum.DateTime: lambda dt: dt.to_iso8601_string(),
        }

    @property
    @abc.abstractmethod
    def bucket(self) -> Optional[str]:
        """
        Bucket name

        Note that this is Optional; not all apps will have all bucket env vars set.
        """

    @validator("bucket", check_fields=False, allow_reuse=True)
    def bucket_exists(cls, v):
        if not storage.Client().bucket(v).exists():
            raise ValueError(f"bucket {v} does not exist")

    @property
    @abc.abstractmethod
    def table(self) -> str:
        """Table name"""

    @property
    @abc.abstractmethod
    def partition_names(self) -> List[str]:
        """
        Defines the partitions into which this artifact is organized.
        The order does matter!
        """

    @property
    def serialized_partitions(self) -> List[str]:
        return serialize_partitions(
            {name: getattr(self, name) for name in self.partition_names}
        )

    @property
    def partition_types(self) -> Dict[str, Type[PartitionType]]:
        return {}

    @root_validator(allow_reuse=True)
    def check_partitions(cls, values):
        # TODO: this isn't great but some partition_names are properties
        if isinstance(cls.partition_names, property):
            return values
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
                f"all partition names must exist as fields or properties; missing {missing}"  # noqa: E702
            )
        return values

    @property
    def name(self):
        return os.path.join(
            self.table,
            *self.serialized_partitions,
            self.filename,
        )

    # This exists because with gcsfs we pretend everything is a path rather than an object in a bucket
    @property
    def path(self):
        return os.path.join(self.bucket, self.name)

    def save_content(
        self,
        content: bytes,
        exclude=None,
        fs: gcsfs.GCSFileSystem = None,
        client: storage.Client = None,
        retry_metadata: bool = False,
        retry_content: bool = False,
    ):
        assert self.bucket is not None
        if (fs is None) == (client is None):
            raise TypeError("must provide a gcsfs file system OR a storage client")

        if fs:
            logging.info(f"saving {humanize.naturalsize(len(content))} to {self.path}")
            fs.pipe(path=self.path, value=content)
            fs.setxattrs(
                path=self.path,
                # This syntax seems silly but it's so we pass the _value_ of PARTITIONED_ARTIFACT_METADATA_KEY
                **{PARTITIONED_ARTIFACT_METADATA_KEY: self.json(exclude=exclude)},
            )

        if client:
            logging.info(
                f"saving {humanize.naturalsize(len(content))} to {self.bucket} {self.name}"
            )
            blob = storage.Blob(
                name=self.name,
                bucket=client.bucket(self.bucket.replace("gs://", "")),
            )

            if retry_content:
                upload_from_string_with_retry(
                    blob=blob,
                    data=content,
                    content_type="application/octet-stream",
                    client=client,
                )
            else:
                upload_from_string(
                    blob=blob,
                    data=content,
                    content_type="application/octet-stream",
                    client=client,
                )

            if retry_metadata:
                set_metadata_with_retry(
                    blob=blob,
                    model=self,
                    exclude=exclude,
                )
            else:
                set_metadata(
                    blob=blob,
                    model=self,
                    exclude=exclude,
                )


# TODO: this should really use a typevar
# This contains several assignment ignores because they are actually ClassVars.
# Maybe the underlying abstract property definition is an anti-pattern.
def fetch_all_in_partition(
    cls: Type[PartitionedGCSArtifact],
    partitions: Dict[str, PartitionType],
    bucket: Optional[str] = None,
    table: Optional[str] = None,
    verbose=False,
) -> Tuple[List[PartitionedGCSArtifact], List[storage.Blob], List[storage.Blob]]:
    if not bucket:
        bucket = cls.bucket  # type: ignore[assignment]

        if not isinstance(bucket, str):
            raise TypeError(
                f"must either pass bucket, or the bucket must resolve to a string; got {type(bucket)}"  # noqa: E702
            )

    if not table:
        table = cls.table  # type: ignore[assignment]

        if not isinstance(table, str):
            raise TypeError(
                f"must either pass table, or the table must resolve to a string; got {type(table)}"  # noqa: E702
            )

    prefix = "/".join(
        [
            table,
            *serialize_partitions(partitions),
            "",
        ]
    )
    if verbose:
        print(f"listing all files in {bucket}/{prefix}")
    client = storage.Client()
    # once Airflow is upgraded to Python 3.9, can use:
    # files = client.list_blobs(bucket.removeprefix("gs://"), prefix=prefix, delimiter=None)
    files = client.list_blobs(
        re.sub(r"^gs://", "", bucket), prefix=prefix, delimiter=None
    )

    parsed: List[PartitionedGCSArtifact] = []
    blobs_with_missing_metadata: List[storage.Blob] = []
    blobs_with_invalid_metadata: List[storage.Blob] = []

    for file in files:
        try:
            parsed.append(
                parse_obj_as(
                    cls, json.loads(file.metadata[PARTITIONED_ARTIFACT_METADATA_KEY])
                )
            )
        except (TypeError, KeyError):
            logging.exception(f"metadata missing on {bucket}/{file.name}")
            blobs_with_missing_metadata.append(file)
        except ValidationError:
            logging.exception(f"invalid metadata found on {bucket}/{file.name}")
            blobs_with_invalid_metadata.append(file)

    return parsed, blobs_with_missing_metadata, blobs_with_invalid_metadata


class ProcessingOutcome(BaseModel, abc.ABC):
    success: bool
    exception: Optional[Exception]

    class Config:
        arbitrary_types_allowed = True
        json_encoders = {Exception: lambda e: str(e)}


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
    def path(self) -> str:
        return f"gs://{self.bucket}/{self.name}"  # noqa: E231

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
    bucket: str,
    table: str,
    prefix_partitions: Dict[str, PartitionType],
    partition_types: Dict[str, Type[PartitionType]],
) -> GCSFileInfo:
    fs = get_fs()
    fs.invalidate_cache()

    prefix_info = fs.info(
        "/".join([bucket, table, *serialize_partitions(prefix_partitions), ""])
    )
    directory = GCSDirectoryInfo(**prefix_info)

    for key, typ in partition_types.items():
        next_dir = sorted(
            directory.children(fs),
            key=lambda o: PARTITION_DESERIALIZERS[typ](o.partition[key]),
            reverse=True,
        )[0]
        # ensure we always get directories
        assert isinstance(next_dir, GCSDirectoryInfo)
        directory = next_dir

    children = directory.children(fs)
    # This is just a convention for us for now; we could also label files with metadata if desired
    # Note: this assumes that there is only 1 file in the final "directory"; this is probably an anti-pattern
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


# This contains several assignment ignores because they are actually ClassVars.
# Maybe the underlying abstract property definition is an anti-pattern.
def get_latest(
    cls: Type[PartitionedGCSArtifact],
    bucket: Optional[str] = None,
    table: Optional[str] = None,
    partition_names: Optional[List[str]] = None,
) -> PartitionedGCSArtifact:
    if not bucket:
        bucket = cls.bucket  # type: ignore[assignment]

        if not isinstance(bucket, str):
            raise TypeError(
                f"must either pass bucket, or the bucket must resolve to a string; got {type(bucket)}"  # noqa: E702
            )

    if not table:
        table = cls.table  # type: ignore[assignment]

        if not isinstance(table, str):
            raise TypeError(
                f"must either pass table, or the table must resolve to a string; got {type(table)}"  # noqa: E702
            )

    if not partition_names:
        partition_names = cls.partition_names  # type: ignore[assignment]

        if not isinstance(partition_names, list):
            raise TypeError(
                f"must either pass partition names, or the partition names must resolve to a list; got {type(partition_names)}"  # noqa: E702
            )

    latest = get_latest_file(
        bucket,
        table,
        prefix_partitions={},
        # TODO: this doesn't pick up the type hint of dt since it's a property; it's fine as a string but we should fix
        partition_types={
            name: get_type_hints(cls).get(name, str) for name in partition_names
        },
    )

    logging.info(f"identified {latest.name} as the most recent extract of {cls}")

    return cls(
        **json.loads(
            get_fs().getxattr(
                path=f"gs://{latest.name}",  # noqa: E231
                attr=PARTITIONED_ARTIFACT_METADATA_KEY,
            )
        )
    )


class AirtableGTFSDataRecord(BaseModel):
    id: str
    name: str
    uri: Optional[str]
    pipeline_url: Optional[str]
    data: Optional[str]
    data_quality_pipeline: Optional[bool]
    schedule_to_use_for_rt_validation: Optional[List[str]]
    authorization_url_parameter_name: Optional[str]
    url_secret_key_name: Optional[str]
    authorization_header_parameter_name: Optional[str]
    header_secret_key_name: Optional[str]
    auth_query_param: Dict[str, str] = {}

    class Config:
        extra = "allow"


class AirtableGTFSDataExtract(PartitionedGCSArtifact):
    bucket: ClassVar[Optional[str]] = AIRTABLE_BUCKET
    table: ClassVar[str] = "california_transit__gtfs_datasets"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    records: List[AirtableGTFSDataRecord]

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    # TODO: this is separate from the general get_latest because our
    #  airtable downloader does not set metadata yet
    @classmethod
    def get_latest(cls) -> "AirtableGTFSDataExtract":
        assert cls.bucket is not None
        latest = get_latest_file(
            cls.bucket,
            cls.table,
            prefix_partitions={},
            # TODO: this doesn't pick up the type hint of dt since it's a property; it's fine as a string but we should fix
            partition_types={
                name: get_type_hints(cls).get(name, str) for name in cls.partition_names
            },
        )

        logging.info(
            f"identified {latest.name} as the most recent extract of gtfs datasets"
        )

        with get_fs().open(latest.name, "rb") as f:
            content = gzip.decompress(f.read())

        return AirtableGTFSDataExtract(
            filename=latest.filename,
            ts=pendulum.parse(latest.partition["ts"], exact=True),
            records=[
                AirtableGTFSDataRecord(**json.loads(row))
                for row in content.decode().splitlines()
            ],
        )


# forbid here as we want to be super careful/strict
class GTFSDownloadConfig(BaseModel, extra=Extra.forbid):
    extracted_at: Optional[pendulum.DateTime]
    name: Optional[str]
    url: HttpUrl
    feed_type: GTFSFeedType
    schedule_url_for_validation: Optional[HttpUrl]
    auth_query_params: Dict[str, str] = {}
    auth_headers: Dict[str, str] = {}
    computed: bool = False

    @validator("extracted_at", allow_reuse=True)
    def coerce_extracted_at(cls, v):
        if isinstance(v, datetime):
            return pendulum.instance(v)
        return v

    @validator("feed_type", pre=True, allow_reuse=True)
    def convert_feed_type(cls, v):
        if not v:
            return None

        if "schedule" in v.lower():
            return GTFSFeedType.schedule
        elif "vehicle" in v.lower():
            return GTFSFeedType.vehicle_positions
        elif "trip" in v.lower():
            return GTFSFeedType.trip_updates
        elif "alerts" in v.lower():
            return GTFSFeedType.service_alerts

        return v

    def build_request(self, auth_dict: Mapping[str, str]) -> Request:
        params = {k: auth_dict[v] for k, v in self.auth_query_params.items()}
        headers = {k: auth_dict[v] for k, v in self.auth_headers.items()}

        # some web servers require user agents or they will throw a 4XX error
        headers[
            "User-Agent"
        ] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:55.0) Gecko/20100101 Firefox/55.0"

        # inspired by: https://stackoverflow.com/questions/18869074/create-url-without-request-execution
        return Request(
            "GET",
            url=self.url,
            params=params,
            headers=headers,
        )

    @property
    def base64_encoded_url(self) -> str:
        # see: https://docs.python.org/3/library/base64.html#base64.urlsafe_b64encode
        # we care about replacing slashes for GCS object names
        # can use: https://www.base64url.com/ to test encoding/decoding
        # convert in bigquery: https://cloud.google.com/bigquery/docs/reference/standard-sql/string_functions#from_base64
        return base64.urlsafe_b64encode(self.url.encode()).decode()

    @property
    def base64_validation_url(self) -> str:
        assert self.schedule_url_for_validation is not None
        return base64.urlsafe_b64encode(
            self.schedule_url_for_validation.encode()
        ).decode()


class GTFSDownloadConfigExtract(PartitionedGCSArtifact):
    bucket: ClassVar[Optional[str]] = GTFS_DOWNLOAD_CONFIG_BUCKET
    table: ClassVar[str] = "gtfs_download_configs"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime

    @validator("ts", allow_reuse=True)
    def coerce_ts(cls, v):
        if isinstance(v, datetime):
            return pendulum.instance(v)
        return v

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()


class GTFSFeedExtract(PartitionedGCSArtifact, ABC):
    ts: pendulum.DateTime
    config: GTFSDownloadConfig
    response_code: int
    response_headers: Optional[Dict[str, str]]

    @validator("ts", allow_reuse=True)
    def coerce_ts(cls, v):
        if isinstance(v, datetime):
            return pendulum.instance(v)
        return v

    @property
    def feed_type(self) -> GTFSFeedType:
        return self.config.feed_type

    @property
    def dt(self) -> pendulum.Date:
        return self.ts.date()

    @property
    def hour(self) -> pendulum.DateTime:
        return self.ts.replace(minute=0, second=0, microsecond=0)

    @property
    def base64_url(self) -> str:
        return self.config.base64_encoded_url


class GTFSScheduleFeedExtract(GTFSFeedExtract):
    bucket: ClassVar[Optional[str]] = SCHEDULE_RAW_BUCKET
    table: ClassVar[str] = GTFSFeedType.schedule
    feed_type: ClassVar[GTFSFeedType] = GTFSFeedType.schedule
    partition_names: ClassVar[List[str]] = ["dt", "ts", "base64_url"]
    reconstructed: bool = False

    @validator("config", allow_reuse=True)
    def is_schedule_type(cls, v: GTFSDownloadConfig):
        if v.feed_type != GTFSFeedType.schedule:
            raise TypeError("a schedule extract must come from a schedule config")
        return v


class GTFSRTFeedExtract(GTFSFeedExtract):
    bucket: ClassVar[Optional[str]] = RT_RAW_BUCKET
    partition_names: ClassVar[List[str]] = ["dt", "hour", "ts", "base64_url"]

    @validator("config", allow_reuse=True)
    def is_rt_type(cls, v: GTFSDownloadConfig):
        if not v.feed_type.is_rt:
            raise TypeError("a realtime extract must come from a realtime config")
        return v

    @property
    def table(self) -> str:
        return self.config.feed_type

    @property
    def timestamped_filename(self):
        """
        Used for RT validation; it's faster to download and validate many files at once, and we need to identify
        them on disk.
        """
        return str(self.filename) + self.ts.strftime("__%Y-%m-%dT%H:%M:%SZ")


def download_feed(
    config: GTFSDownloadConfig,
    auth_dict: Mapping[str, str],
    ts: pendulum.DateTime,
    default_filename="feed",
    **request_kwargs,
) -> Tuple[GTFSFeedExtract, bytes]:
    s = Session()
    r = s.prepare_request(config.build_request(auth_dict))
    resp = s.send(r, **request_kwargs)
    resp.raise_for_status()

    disposition_header = resp.headers.get(
        "content-disposition", resp.headers.get("Content-Disposition")
    )

    if disposition_header:
        if disposition_header.startswith("filename="):
            # sorry; cgi won't parse unless it's prefixed with the disposition type
            disposition_header = f"attachment; {disposition_header}"  # noqa: E702
        _, params = cgi.parse_header(disposition_header)
        disposition_filename = params.get("filename")
    else:
        disposition_filename = None

    filename = (
        disposition_filename
        or (os.path.basename(resp.url) if resp.url.endswith(".zip") else None)
        or default_filename
    )

    extract_class = (
        GTFSRTFeedExtract if config.feed_type.is_rt else GTFSScheduleFeedExtract
    )
    extract = extract_class(
        filename=filename,
        config=config,
        response_code=resp.status_code,
        response_headers=resp.headers,
        ts=ts,
    )

    return extract, resp.content


if __name__ == "__main__":
    # just some useful testing stuff
    latest = AirtableGTFSDataExtract.get_latest()
    print(latest.path, len(latest.records))
    extract = get_latest(GTFSDownloadConfigExtract)
    fs = get_fs()
    with fs.open(extract.path, "rb") as f:
        content = gzip.decompress(f.read())
    records = [
        GTFSDownloadConfig(**json.loads(row)) for row in content.decode().splitlines()
    ]
    download_feed(records[0], auth_dict={}, ts=pendulum.now(), timeout=1)
    print("downloaded a thing!")
    sys.exit(0)

    # use Etc/UTC instead of UTC
    # Etc/UTC is what the pods get as a timezone... and it serializes to 2022-08-18T00:00:00+00:00
    # whereas UTC serializes to 2022-08-18T00:00:00Z
    # this should probably be checked in the partitioned artifact?
    yesterday_noon = pendulum.yesterday("Etc/UTC").replace(
        minute=0, second=0, microsecond=0
    )
    vp_files, _, _ = fetch_all_in_partition(
        cls=GTFSRTFeedExtract,
        fs=get_fs(),
        partitions={
            "dt": yesterday_noon.date(),
            "hour": yesterday_noon,
        },
        table=GTFSFeedType.vehicle_positions,
        verbose=True,
        progress=True,
    )
    schedule_files, _, _ = fetch_all_in_partition(
        cls=GTFSScheduleFeedExtract,
        fs=get_fs(),
        partitions={
            "dt": pendulum.parse("2022-09-07", exact=True),
        },
        verbose=True,
        progress=True,
    )
    latest_schedule = get_latest_file(
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        prefix_partitions={
            "dt": pendulum.parse("2022-08-12", exact=True),
            "base64_url": "aHR0cHM6Ly9yaWRlbXZnby5vcmcvZ3Rmcw==",
        },
        partition_types={
            "ts": pendulum.DateTime,
        },
    )
