import json
import os

import pytest
from google.protobuf.message import DecodeError
from hooks.gtfs_rt_feed_hook import GTFSRTFeedHook


class TestGTFSRTFeedHook:
    @pytest.fixture
    def hook(self) -> GTFSRTFeedHook:
        return GTFSRTFeedHook()

    @pytest.fixture
    def invalid_gtfs_rt_feed_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "..", "fixtures", "invalid_trip_updates.pb64"
            )
        )

    @pytest.fixture
    def invalid_gtfs_rt_feed_data(self, invalid_gtfs_rt_feed_path: str) -> bytes:
        with open(invalid_gtfs_rt_feed_path, "rb") as file:
            return file.read()

    @pytest.fixture
    def gtfs_rt_feed_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(__file__), "..", "fixtures", "service_alerts.pb"
            )
        )

    @pytest.fixture
    def gtfs_rt_feed_data(self, gtfs_rt_feed_path: str) -> bytes:
        with open(gtfs_rt_feed_path, "rb") as file:
            return file.read()

    @pytest.mark.vcr()
    def test_parse(self, hook: GTFSRTFeedHook, gtfs_rt_feed_data: bytes):
        result = hook.parse(
            object_name="feed",
            metadata={"PARTITIONED_ARTIFACT_METADATA": json.dumps({})},
            source=gtfs_rt_feed_data,
        )
        assert result.results() == {
            "step": "parse",
            "success": True,
            "header": {
                "gtfsrealtimeversion": "2.0",
                "incrementality": "FULL_DATASET",
                "timestamp": "1777593552",
            },
            "exception": None,
            "blob_path": None,
            "aggregation": {"step": "parse", "filename": "feed", "first_extract": None},
            "extract": {},
            "process_stderr": None,
        }

    @pytest.mark.vcr()
    def test_parse_invalid(
        self, hook: GTFSRTFeedHook, invalid_gtfs_rt_feed_data: bytes
    ):
        result = hook.parse(
            object_name="feed",
            metadata={"PARTITIONED_ARTIFACT_METADATA": json.dumps({})},
            source=invalid_gtfs_rt_feed_data,
        )
        assert isinstance(result.exception, DecodeError)
        assert (
            str(result.exception)
            == "Error parsing message with type 'transit_realtime.FeedMessage'"
        )
        assert result.results() == {
            "step": "parse",
            "success": False,
            "header": None,
            "exception": "Error parsing message with type 'transit_realtime.FeedMessage'",
            "blob_path": "feed",
            "aggregation": {"step": "parse", "filename": "feed", "first_extract": None},
            "extract": {},
            "process_stderr": None,
        }
