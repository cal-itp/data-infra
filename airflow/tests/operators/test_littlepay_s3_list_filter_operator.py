import json
import os
from contextlib import contextmanager

import pytest
from freezegun import freeze_time
from moto import mock_aws
from operators.littlepay_s3_list_filter_operator import LittlepayS3ListFilterOperator

from airflow.providers.amazon.aws.hooks.s3 import S3Hook
from airflow.providers.google.cloud.hooks.gcs import GCSHook

SOURCE_BUCKET = "mock-littlepay-bucket"
SOURCE_PATH = "atn/v3/authorisations/pytest_filter_unchanged_20261103.psv"
FILENAME = os.path.basename(SOURCE_PATH)
GCS_OBJECT = (
    f"authorisations/instance=atn/filename={FILENAME}/"
    f"ts=2026-11-03T00:00:00+00:00/{FILENAME}"
)


@pytest.fixture
def bucket_name():
    return os.environ["CALITP_BUCKET__LITTLEPAY_RAW_V3"].removeprefix("gs://")


@pytest.fixture
def operator():
    return LittlepayS3ListFilterOperator(
        task_id="test_littlepay_list_filter",
        provider="atn",
        source_bucket=SOURCE_BUCKET,
        source_prefix="atn/v3",
        aws_conn_id="aws_default",
        destination_bucket=os.environ["CALITP_BUCKET__LITTLEPAY_RAW_V3"],
    )


def create_s3_file(s3_hook, source_path=SOURCE_PATH):
    s3_hook.create_bucket(SOURCE_BUCKET)
    s3_hook.load_string(
        string_data="test littlepay content",
        key=source_path,
        bucket_name=SOURCE_BUCKET,
    )
    return s3_hook.get_key(
        bucket_name=SOURCE_BUCKET,
        key=source_path,
    ).get()


def upload_gcs_file(gcs_hook, bucket_name, s3_file, etag=None, object_name=GCS_OBJECT):
    metadata = {
        "PARTITIONED_ARTIFACT_METADATA": json.dumps(
            {
                "s3object": {
                    "LastModified": s3_file["LastModified"].isoformat(),
                    "ETag": etag if etag is not None else s3_file["ETag"],
                }
            }
        )
    }
    gcs_hook.upload(
        bucket_name=bucket_name,
        object_name=object_name,
        data="test littlepay content",
        metadata=metadata,
    )


@contextmanager
def temporary_gcs_object(gcs_hook, bucket_name, object_name):
    try:
        yield
    finally:
        gcs_hook.delete(
            bucket_name=bucket_name,
            object_name=object_name,
        )


@mock_aws
@pytest.mark.vcr
@freeze_time("2026-11-03 12:00:00")
def test_unchanged_file_is_excluded(operator, bucket_name):
    s3_file = create_s3_file(S3Hook())
    gcs_hook = GCSHook()

    with temporary_gcs_object(gcs_hook, bucket_name, GCS_OBJECT):
        upload_gcs_file(gcs_hook, bucket_name, s3_file)
        assert operator.execute(context={}) == []


@mock_aws
@pytest.mark.vcr
def test_modified_file_is_included(operator, bucket_name):
    source_path = "atn/v3/authorisations/pytest_filter_modified_20261103.psv"
    filename = os.path.basename(source_path)
    object_name = (
        f"authorisations/instance=atn/filename={filename}/"
        f"ts=2026-11-03T00:00:00+00:00/{filename}"
    )

    s3_file = create_s3_file(S3Hook(), source_path)
    gcs_hook = GCSHook()
    with temporary_gcs_object(gcs_hook, bucket_name, object_name):
        upload_gcs_file(
            gcs_hook,
            bucket_name,
            s3_file,
            etag='"old-etag"',
            object_name=object_name,
        )

        assert operator.execute(context={}) == [source_path]


@mock_aws
@pytest.mark.vcr
def test_new_file_is_included(operator):
    source_path = "atn/v3/authorisations/pytest_filter_new_20261103.psv"
    create_s3_file(S3Hook(), source_path)

    assert operator.execute(context={}) == [source_path]


@mock_aws
@pytest.mark.vcr
def test_empty_s3_listing_returns_no_files(operator):
    S3Hook().create_bucket(SOURCE_BUCKET)

    assert operator.execute(context={}) == []
