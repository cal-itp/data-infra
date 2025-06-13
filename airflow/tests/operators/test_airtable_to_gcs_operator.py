import gzip
import json
import os
from datetime import datetime, timezone

import pytest
from operators.airtable_to_gcs_operator import AirtableCleaner, AirtableToGCSOperator


def before_record_cb(request):
    if request.host == "sts.googleapis.com" and request.path == "/v1/oauthtoken":
        return None
    return request


class TestAirtableRowsCleaner:
    def test_cleaning_a_standard_row(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": "pinto"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": "pinto"}]

    def test_cleaning_a_key_with_spaces(self):
        airtable_rows = [{"id": "abc123", "fields": {"taco type": "beans"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "taco_type": "beans"}]

    def test_cleaning_a_key_with_a_leading_digit(self):
        airtable_rows = [{"id": "abc123", "fields": {"1taco": "nope"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "_1taco": "nope"}]

    def test_cleaning_a_numeric_key(self):
        airtable_rows = [{"id": "abc123", "fields": {1: "tortilla"}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "_1": "tortilla"}]

    def test_cleaning_a_standard_array(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": ["pinto", "black"]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": ["pinto", "black"]}]

    def test_cleaning_a_standard_dict(self):
        airtable_rows = [
            {"id": "abc123", "fields": {"toppings": {"cilantro": "fresh"}}}
        ]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "toppings": {"cilantro": "fresh"}}]

    def test_cleaning_a_string_array_with_none_values(self):
        airtable_rows = [{"id": "abc123", "fields": {"beans": ["pinto", None]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "beans": ["pinto", ""]}]

    def test_cleaning_a_numeric_array_with_none_values(self):
        airtable_rows = [{"id": "abc123", "fields": {"servings": [1, None, 3]}}]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [{"id": "abc123", "servings": [1, -1, 3]}]

    def test_cleaning_a_dict_with_nested_none_values(self):
        airtable_rows = [
            {
                "id": "abc123",
                "fields": {"daily_servings": {"monday": [1, None], "tuesday": [3]}},
            }
        ]
        cleaner = AirtableCleaner(airtable_rows)
        assert cleaner.clean() == [
            {"id": "abc123", "daily_servings": {"monday": [1, -1], "tuesday": [3]}}
        ]


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
        print(datetime.now(timezone.utc))
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
