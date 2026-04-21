import os
from datetime import datetime

import pytest
import requests
from google.transit import gtfs_realtime_pb2
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


class TestDownloader:
    @pytest.fixture
    def fixture_certificate_path(self) -> str:
        return os.path.join(os.path.dirname(__file__), "fixtures", "certificates")

    @pytest.fixture
    def current_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-07T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://avl.yctd.org/RealTime/GTFS_ServiceAlerts.pb"

    @pytest.fixture
    def data(self, current_time: datetime, url: str) -> dict:
        return {
            "publish_time": "2026-04-01T00:01:23.45+00:00",
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "service_alerts",
            "name": "Example",
            "schedule_url_for_validation": "http://www.yolobus.com/GTFS/google_transit.zip",
            "url": url,
        }

    @pytest.fixture
    def uctransit_data(self, current_time: datetime, url: str) -> dict:
        return {
            "publish_time": "2026-04-01T00:01:23.45+00:00",
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "service_alerts",
            "name": "Example",
            "schedule_url_for_validation": "https://example.com/google_transit.zip",
            "url": "https://uctransit.info/gtfs-rt/vehiclepositions",
        }

    @pytest.fixture
    def configuration(self, current_time: datetime, data: dict) -> Configuration:
        return Configuration.resolve(**data)

    @pytest.fixture
    def example_configuration(
        self, current_time: datetime, uctransit_data: dict
    ) -> Configuration:
        return Configuration.resolve(**uctransit_data)

    @pytest.fixture
    def downloader(self, configuration: Configuration) -> Downloader:
        return Downloader(configuration=configuration)

    @pytest.fixture
    def uctransit_downloader(
        self, example_configuration: Configuration, fixture_certificate_path: str
    ) -> Downloader:
        return Downloader(
            configuration=example_configuration,
            certificate_path=fixture_certificate_path,
        )

    @pytest.mark.vcr
    def test_downloader_retrieves_feed_with_pinned_certificate(
        self, uctransit_downloader: Downloader
    ) -> None:
        with pytest.raises(requests.exceptions.HTTPError) as excinfo:
            uctransit_downloader.get()
        assert "404" in str(excinfo.value)
        assert "Not Found" in str(excinfo.value)

    @pytest.mark.vcr
    def test_downloader_retrieves_feed(self, downloader: Downloader) -> None:
        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(downloader.get().content())
        assert len(feed.entity) > 0
