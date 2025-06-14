import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from operators.airtable_to_gcs_operator import AirtableToGCSOperator


def before_record_cb(request):
    if request.host == "sts.googleapis.com" and request.path == "/v1/oauthtoken":
        return None
    return request


class TestAirtableToGCSOperator:
    @pytest.fixture
    def operator(self) -> AirtableToGCSOperator:
        return AirtableToGCSOperator(
            task_id="airtable_to_gcs",
            airtable_conn_id="airtable_default",
            air_base_id="appPnJWrQ7ui4UmIl",
            air_base_name="california_transit",
            air_table_name="county geography",
            gcp_conn_id="google_cloud_default",
            bucket=os.environ.get("CALITP_BUCKET__AIRTABLE"),
            current_time=datetime.fromisoformat("2025-06-01"),
        )

    @pytest.mark.vcr(
        allow_playback_repeats=True, before_record_request=before_record_cb
    )
    def test_execute(self, operator: AirtableToGCSOperator):
        operator.execute({})
        compressed_result = operator.gcs_hook().download(
            bucket_name=os.environ.get("CALITP_BUCKET__AIRTABLE").replace("gs://", ""),
            object_name=operator.object_path(),
        )
        airtable_rows = operator.airtable_hook().read(
            air_base_id="appPnJWrQ7ui4UmIl",
            air_table_name="county geography",
        )
        decompressed_result = gzip.decompress(compressed_result)
        result = [json.loads(x) for x in decompressed_result.splitlines()]
        assert result[0]["id"] == airtable_rows[0]["id"]
        for key, _ in airtable_rows[0]["fields"].items():
            assert key.lower().replace(" ", "_") in result[0]
