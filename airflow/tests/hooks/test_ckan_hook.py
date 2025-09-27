from io import StringIO
import os

import pytest
from airflow.providers.google.cloud.hooks.gcs import GCSHook
from hooks.ckan_hook import CKANHook


class TestCKANHook:
    @pytest.fixture
    def hook(self) -> CKANHook:
        return CKANHook(ckan_conn_id="http_ckan")

    @pytest.fixture
    def gcs_hook(self) -> GCSHook:
        return GCSHook()

    @pytest.mark.vcr()
    def test_upload(self, gcs_hook: GCSHook, hook: CKANHook):
        metadata_csv = gcs_hook.download(
            bucket_name=os.environ.get("CALITP_BUCKET__PUBLISH").replace(
                "gs://", ""
            ),
            object_name=os.path.join(
                "california_open_data__metadata",
                "dt=2025-06-01",
                "ts=2025-06-01T00:00:00+00:00",
                "metadata.csv"
            )
        )
        file = StringIO(metadata_csv.decode())
        result = hook.read_metadata(
            resource_id="53c05c25-e467-407a-bb29-303875215adc",
        )
        assert result == "very resourceful"
