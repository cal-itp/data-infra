from datetime import datetime

import pytest
from google.transit import gtfs_realtime_pb2
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


class TestDownloader:
    @pytest.fixture
    def current_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-07T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://avl.yctd.org/RealTime/GTFS_ServiceAlerts.pb"

    @pytest.fixture
    def data(self, current_time: datetime, url: str) -> dict:
        return {
            "published_time": "2026-04-01T00:01:23.45+00:00",
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
    def configuration(self, current_time: datetime, data: dict) -> Configuration:
        return Configuration.resolve(**data)

    @pytest.fixture
    def downloader(self, configuration: Configuration) -> Downloader:
        return Downloader(configuration=configuration)

    @pytest.mark.vcr
    def test_downloader_retrieves_feed(self, downloader: Downloader) -> None:
        feed = gtfs_realtime_pb2.FeedMessage()
        feed.ParseFromString(downloader.get().content())
        assert len(feed.entity) > 0
