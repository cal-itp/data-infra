import os
from io import StringIO

import pytest
from ckanapi import errors
from hooks.ckan_hook import CKANHook

from airflow.providers.google.cloud.hooks.gcs import GCSHook


class TestCKANHook:
    @pytest.fixture
    def hook(self) -> CKANHook:
        return CKANHook(ckan_conn_id="http_ckan")

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.mark.vcr()
    def test_find_resource_id(self, hook: CKANHook):
        resource_id = hook.find_resource_id(
            dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
            resource_name="Cal-ITP GTFS Schedule Metadata",
        )
        assert resource_id == "bedac9e4-4fce-4287-bf60-0064ddaf999c"

    @pytest.mark.vcr()
    def test_find_nonexistent_resource(self, hook: CKANHook):
        resource_id = hook.find_resource_id(
            dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
            resource_name="Nope",
        )
        assert resource_id is None

    @pytest.mark.vcr()
    def test_find_nonexistent_dataset(self, hook: CKANHook):
        with pytest.raises(errors.NotFound):
            hook.find_resource_id(
                dataset_id="rick-astley-metrics",
                resource_name="Nope",
            )

    @pytest.mark.vcr()
    def test_upload(self, gcs_hook: GCSHook, hook: CKANHook):
        metadata_csv = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH").replace("gs://", ""),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv",
            ),
        )
        file = StringIO(metadata_csv.decode())
        metadata_result = hook.upload(
            resource_id="bedac9e4-4fce-4287-bf60-0064ddaf999c", file=file
        )
        assert (
            metadata_result
            == {
                "cache_last_updated": None,
                "cache_url": None,
                "datastore_active": True,
                "datastore_contains_all_records_of_source_file": True,
                "format": "CSV",
                "id": "bedac9e4-4fce-4287-bf60-0064ddaf999c",
                "name": "Cal-ITP GTFS Schedule Metadata",
                "package_id": "ba2a80ce-2065-427b-a8fb-8e5bed44cfc3",
                "state": "active",
                "url": "https://test-data.technology.ca.gov/dataset/ba2a80ce-2065-427b-a8fb-8e5bed44cfc3/resource/bedac9e4-4fce-4287-bf60-0064ddaf999c/download/upload",
                "url_type": "upload",
            }
            | metadata_result
        )

    @pytest.mark.vcr()
    def test_multipart_upload(self, gcs_hook: GCSHook, hook: CKANHook):
        bucket_name = os.environ.get("CALITP_BUCKET__PUBLISH").replace("gs://", "")
        csv_file_names = gcs_hook.list(
            bucket_name=bucket_name,
            prefix=os.path.join(
                "california_open_data__agency",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "agency",
            ),
        )
        with CKANHook(
            ckan_conn_id="http_ckan",
            resource_id="7cdf8cef-ddcb-4c17-8820-74ee2f29a06c",
            resource_name="agency",
        ) as ckan:
            for file_name in csv_file_names:
                data = gcs_hook.download(
                    bucket_name=bucket_name,
                    object_name=file_name,
                )
                result = ckan.multi_upload(file=StringIO(data.decode()))

        assert result == {
            "partNumber": "1",
            "ETag": '"3585fb7321ee203d33aa5dd250b50bb3"',
        }
