import json
from datetime import UTC, datetime
from unittest.mock import MagicMock, patch

import pytest
from download_and_parse_littlepay import filter_existing_littlepay_files

SOURCE_PATH = "atn/v3/authorisations/202510241114_authorisations.psv"
GCS_OBJECT = (
    "authorisations/instance=atn/"
    "filename=202510241114_authorisations.psv/"
    "ts=2025-06-01T00:00:00+00:00/"
    "202510241114_authorisations.psv"
)
LAST_MODIFIED = datetime(2025, 10, 24, 11, 14, tzinfo=UTC)
ETAG = '"abc123"'


@pytest.fixture
def mock_hooks():
    with (
        patch("download_and_parse_littlepay.S3Hook") as s3_class,
        patch("download_and_parse_littlepay.GCSHook") as gcs_class,
    ):
        s3 = s3_class.return_value
        gcs = gcs_class.return_value

        paginator = MagicMock()
        paginator.paginate.return_value = [
            {
                "Contents": [
                    {
                        "Key": SOURCE_PATH,
                        "LastModified": LAST_MODIFIED,
                        "ETag": ETAG,
                    }
                ]
            }
        ]
        s3.get_conn.return_value.get_paginator.return_value = paginator

        gcs.list.return_value = [GCS_OBJECT]
        gcs.get_blob_update_time.return_value = LAST_MODIFIED
        gcs.get_metadata.return_value = {
            "PARTITIONED_ARTIFACT_METADATA": json.dumps(
                {
                    "s3object": {
                        "LastModified": LAST_MODIFIED.isoformat(),
                        "ETag": ETAG,
                    }
                }
            )
        }

        yield s3, gcs


def run_filter():
    return filter_existing_littlepay_files.function(
        source_paths=[SOURCE_PATH],
        provider="atn",
        source_bucket="mock-littlepay-bucket",
        source_prefix="atn/v3",
        aws_conn_id="aws_atn",
        destination_bucket="gs://mock-littlepay-raw",
    )


def test_unchanged_file_is_excluded(mock_hooks):
    assert run_filter() == []


def test_modified_file_is_included(mock_hooks):
    _, gcs = mock_hooks
    gcs.get_metadata.return_value = {
        "PARTITIONED_ARTIFACT_METADATA": json.dumps(
            {
                "s3object": {
                    "LastModified": LAST_MODIFIED.isoformat(),
                    "ETag": '"old-etag"',
                }
            }
        )
    }

    assert run_filter() == [SOURCE_PATH]


def test_new_file_is_included(mock_hooks):
    _, gcs = mock_hooks
    gcs.list.return_value = []

    assert run_filter() == [SOURCE_PATH]


def test_missing_s3_file_is_excluded(mock_hooks):
    s3, _ = mock_hooks
    s3.get_conn.return_value.get_paginator.return_value.paginate.return_value = [
        {"Contents": []}
    ]

    assert run_filter() == []
