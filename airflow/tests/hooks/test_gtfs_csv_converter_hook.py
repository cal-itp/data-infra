import json
import os

import pytest
from hooks.gtfs_csv_converter_hook import GTFSCSVConverter


class TestGTFSCSVConverter:
    @pytest.fixture
    def extract_config(self) -> dict:
        return {
            "extracted_at": "2025-06-01T00:00:00+00:00",
            "name": "Octa Schedule",
            "url": "http://example.com/gtfs.zip",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def extracted_file(self) -> dict:
        return {
            "filename": "stops.txt",
            "ts": "2025-06-02T00:00:00+00:00",
            "extract_config": {
                "extracted_at": "2025-06-01T00:00:00+00:00",
                "name": "Octa Schedule",
                "url": "http://example.com/gtfs.zip",
                "feed_type": "schedule",
                "schedule_url_for_validation": None,
                "auth_query_params": {},
                "auth_headers": {},
                "computed": False,
            },
            "original_filename": "stops.txt",
        }

    @pytest.fixture
    def byte_order_mark_file_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.dirname(os.path.realpath(__file__))),
                "fixtures",
                "octa-windows-byte-order-marker-stops.csv",
            )
        )

    @pytest.fixture
    def byte_order_mark_source_data(self, byte_order_mark_file_path: str) -> bytes:
        with open(byte_order_mark_file_path, mode="rb") as f:
            return f.read()

    @pytest.fixture
    def byte_order_mark_hook(
        self,
        byte_order_mark_source_data: bytes,
        extracted_file: dict,
        extract_config: dict,
    ) -> GTFSCSVConverter:
        return GTFSCSVConverter(
            filename="stops.txt",
            data=byte_order_mark_source_data,
            extracted_file=extracted_file,
            extract_config=extract_config,
        )

    def test_convert_byte_order_marker(
        self,
        byte_order_mark_hook: GTFSCSVConverter,
    ):
        results = byte_order_mark_hook.convert(current_date="2025-06-02T00:00:00+00:00")

        assert results.valid() is True
        assert json.loads(list(list(results.chunks(size=1))[0])[0]) == {
            "_line_number": 5246,
            "stop_id": "8681",
            "stop_code": "8681",
            "stop_name": "PACIFIC COAST-WARNER",
            "stop_desc": "",
            "stop_lat": "33.711852",
            "stop_lon": "-118.063556",
            "zone_id": "",
            "stop_url": "",
            "location_type": "",
            "parent_station": "",
            "stop_timezone": "",
        }

    @pytest.fixture
    def file_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.dirname(os.path.realpath(__file__))),
                "fixtures",
                "stops.csv",
            )
        )

    @pytest.fixture
    def source_data(self, file_path: str) -> bytes:
        with open(file_path, mode="rb") as f:
            return f.read()

    @pytest.fixture
    def hook(
        self,
        source_data: bytes,
        extracted_file: dict,
        extract_config: dict,
    ) -> GTFSCSVConverter:
        return GTFSCSVConverter(
            filename="stops.txt",
            data=source_data,
            extracted_file=extracted_file,
            extract_config=extract_config,
        )

    def test_convert_csv(
        self,
        hook: GTFSCSVConverter,
    ):
        results = hook.convert(current_date="2025-06-02T00:00:00+00:00")

        assert results.valid() is True
        assert json.loads(list(list(results.chunks(size=1))[0])[0]) == {
            "_line_number": 363,
            "level_id": "",
            "location_type": "0",
            "parent_station": "",
            "platform_code": "",
            "stop_id": "8068151",
            "stop_code": "",
            "stop_name": "Walmart Los Banos",
            "stop_desc": "",
            "stop_lat": "37.054239",
            "stop_lon": "-120.877606",
            "stop_url": "",
            "stop_timezone": "",
            "wheelchair_boarding": "0",
            "zone_id": "",
        }
