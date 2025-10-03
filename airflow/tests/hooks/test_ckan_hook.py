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
        with pytest.raises(KeyError):
            hook.find_resource_id(
                dataset_id="cal-itp-gtfs-ingest-pipeline-dataset",
                resource_name="Nope",
            )

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
                "ckan_url": "https://test-data.technology.ca.gov",
                "datastore_active": True,
                "datastore_contains_all_records_of_source_file": True,
                "description": "",
                "format": "CSV",
                "hash": "540ff57f389d699ed027208e2eba76a8",
                "id": "bedac9e4-4fce-4287-bf60-0064ddaf999c",
                "ignore_hash": False,
                "is_data_dict_populated": False,
                "mimetype": None,
                "mimetype_inner": None,
                "name": "Metadata",
                "original_url": "https://test-data.technology.ca.gov/dataset/ba2a80ce-2065-427b-a8fb-8e5bed44cfc3/resource/bedac9e4-4fce-4287-bf60-0064ddaf999c/download/upload",
                "package_id": "ba2a80ce-2065-427b-a8fb-8e5bed44cfc3",
                "position": 0,
                "resource_type": None,
                "set_url_type": False,
                "size": 19269,
                "state": "active",
                "url": "https://test-data.technology.ca.gov/dataset/ba2a80ce-2065-427b-a8fb-8e5bed44cfc3/resource/bedac9e4-4fce-4287-bf60-0064ddaf999c/download/upload",
                "url_type": "upload",
            }
            | metadata_result
        )
