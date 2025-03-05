import concurrent
import json
import os
import traceback
from concurrent.futures import Future, ThreadPoolExecutor
from datetime import datetime
from typing import ClassVar, Dict, List, Optional

import boto3
import pendulum
from calitp_data_infra.auth import get_secret_by_name
from calitp_data_infra.storage import (
    PARTITIONED_ARTIFACT_METADATA_KEY,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    get_fs,
    get_latest_file,
)
from pydantic.class_validators import validator
from pydantic.error_wrappers import ValidationError
from pydantic.main import BaseModel
from tqdm import tqdm
from tqdm.contrib.logging import logging_redirect_tqdm

from airflow.models import BaseOperator

# new bucket because of schema changes, need to investigate backfill status with transitions to v3 or handling otherwise
LITTLEPAY_RAW_BUCKET = os.getenv("CALITP_BUCKET__LITTLEPAY_RAW_V3")


class LittlepayFileKey(str):
    @classmethod
    def __get_validators__(cls):
        yield cls.validate

    @classmethod
    def validate(cls, v):
        # new filename format has 4 parts instead of 3 (with the addition of the feed version in filename)
        assert len(v.split("/")) == 4 and v.endswith(".psv")
        return cls(v)

    @property
    def agency(self) -> str:
        return self.split("/")[0]

    # entity is now in location 2 (instead of 1) as the feed version is in location 1
    @property
    def entity(self) -> str:
        return self.split("/")[2]

    # filename is now in location 3 (instead of 2)
    @property
    def filename(self) -> str:
        return self.split("/")[3]  # Return full filename with extension


class LittlepayS3Object(BaseModel):
    Key: LittlepayFileKey
    LastModified: pendulum.DateTime
    ETag: str
    Size: int
    StorageClass: str


class RawLittlepayFileExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = LITTLEPAY_RAW_BUCKET
    partition_names: ClassVar[List[str]] = ["instance", "filename", "ts"]
    instance: str
    filename: str
    ts: pendulum.DateTime
    s3bucket: str
    s3object: LittlepayS3Object

    @validator("ts", allow_reuse=True)
    def coerce_ts(cls, v):
        if isinstance(v, datetime):
            return pendulum.instance(v)
        return v

    @property
    def table(self) -> str:
        return self.s3object.Key.entity

    # TODO: why does this not override the parent model field?
    # @property
    # def filename(self) -> str:
    #     return self.s3object.Key.filename


# We shouldn't save files that we skip since that's an unbounded, increasing list.
class RawLittlepayFileOutcome(ProcessingOutcome):
    extract: RawLittlepayFileExtract
    prior: Optional[
        RawLittlepayFileExtract
    ]  # prior existing implies an update to an existing file


class RawLittlepaySyncJobResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = LITTLEPAY_RAW_BUCKET
    table: ClassVar[str] = "raw_littlepay_sync_job_result"
    partition_names: ClassVar[List[str]] = ["instance", "ts"]
    instance: str
    ts: pendulum.DateTime


def sync_file(
    src_bucket: str, file: RawLittlepayFileExtract, s3client, fs
) -> Optional[RawLittlepayFileOutcome]:
    try:
        # TODO: this kinda overlaps with get_latest()
        fileinfo = get_latest_file(
            bucket=file.bucket,
            table=file.table,
            prefix_partitions={
                "instance": file.instance,
                "filename": file.filename,
            },
            partition_types={
                "ts": pendulum.DateTime,
            },
        )
        try:
            metadata_str = fs.getxattr(
                path=f"gs://{fileinfo.name}",  # noqa: E231
                attr=PARTITIONED_ARTIFACT_METADATA_KEY,
            )
        except KeyError:
            print(f"metadata missing on {fileinfo.name}")
            raise
        prior = RawLittlepayFileExtract(**json.loads(metadata_str))
        save = (
            file.s3object.LastModified != prior.s3object.LastModified
            or file.s3object.ETag != prior.s3object.ETag
        )
    except FileNotFoundError:
        save = True
        prior = None

    if save:
        content = s3client.get_object(Bucket=src_bucket, Key=file.s3object.Key)[
            "Body"
        ].read()
        file.save_content(content=content, fs=fs)
        return RawLittlepayFileOutcome(
            success=True,
            extract=file,
            prior=prior,
        )
    return None


class LittlepayRawSyncV3(BaseOperator):
    template_fields = ()

    def __init__(
        self,
        *args,
        instance: str,
        # pull src_bucket from task yml
        src_bucket: str,
        access_key_secret_name: str,
        **kwargs,
    ):
        self.instance = instance
        # deprecate because source bucket names are not predictable in v3
        # self.src_bucket = f"littlepay-prod-{instance}-datafeed"
        self.src_bucket = src_bucket
        self.access_key_secret_name = access_key_secret_name
        super().__init__(**kwargs)

    def execute(self, context):
        assert LITTLEPAY_RAW_BUCKET is not None

        start = pendulum.now()
        access_key = json.loads(get_secret_by_name(self.access_key_secret_name))
        print(f"Successfully loaded secret {self.access_key_secret_name}")
        s3client = boto3.client(
            "s3",
            aws_access_key_id=access_key["AccessKey"]["AccessKeyId"],
            aws_secret_access_key=access_key["AccessKey"]["SecretAccessKey"],
        )

        list_kwargs = {
            "Bucket": self.src_bucket,
        }

        files: List[RawLittlepayFileExtract] = []

        # 1000 objects per page; just stop us from accidentally going forever
        for _ in tqdm(range(1000)):
            resp = s3client.list_objects_v2(**list_kwargs)

            for content in resp["Contents"]:
                if content["Key"] == self.instance:
                    # Weird 0-length file(s) that seem to get created everywhere
                    continue
                try:
                    obj = LittlepayS3Object(**content)
                    file = RawLittlepayFileExtract(
                        instance=self.instance,
                        ts=start,
                        s3bucket=self.src_bucket,
                        s3object=obj,
                        filename=obj.Key.filename,
                    )
                    files.append(file)
                except ValidationError:
                    print(content, flush=True)
                    raise

            if resp["IsTruncated"]:
                list_kwargs["ContinuationToken"] = resp["NextContinuationToken"]
            else:
                break
        else:
            raise RuntimeError("failed to page fully through bucket")

        print(
            f"Found {len(files)} source files in {self.src_bucket}; diffing and copying to {RawLittlepayFileExtract.bucket}."  # noqa: E702
        )

        fs = get_fs()
        extracted_files: List[RawLittlepayFileExtract] = []
        failures = []
        with logging_redirect_tqdm():
            pbar = tqdm(total=len(files))
            with ThreadPoolExecutor(max_workers=4) as pool:
                futures: Dict[Future, RawLittlepayFileExtract] = {
                    pool.submit(
                        sync_file,
                        src_bucket=self.src_bucket,
                        file=file,
                        s3client=s3client,
                        fs=fs,
                    ): file
                    for i, file in enumerate(files)
                }
                for future in concurrent.futures.as_completed(futures):
                    pbar.update(1)
                    try:
                        ret = future.result()
                        if ret:
                            extracted_files.append(ret)
                    except KeyboardInterrupt:
                        raise
                    except Exception as e:
                        print(
                            f"exception during processing of {futures[future].s3object.Key} -> {futures[future].path}: {str(e)}"
                        )
                        traceback.print_exc()
                        failures.append(e)
            del pbar

        RawLittlepaySyncJobResult(
            instance=self.instance,
            ts=start,
            filename="results.jsonl",
        ).save_content(
            content="\n".join(e.json() for e in extracted_files).encode(), fs=fs
        )

        if failures:
            raise RuntimeError(str(failures))
