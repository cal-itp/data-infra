import json
import os
from datetime import datetime

import pytest
from google.cloud.storage import Blob, Bucket, Client
from gtfs_rt_archiver.archiver import Archiver
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.downloader import Downloader


class TestArchiver:
    @pytest.fixture
    def published_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-01T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://avl.yctd.org/RealTime/GTFS_ServiceAlerts.pb"

    @pytest.fixture
    def data(self, published_time: datetime, url: str) -> dict:
        return {
            "published_time": published_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "service_alerts",
            "name": "Example",
            "schedule_url_for_validation": "http://www.yolobus.com/GTFS/google_transit.zip",
            "url": url,
        }

    @pytest.fixture
    def configuration(self, data: dict) -> Configuration:
        return Configuration.resolve(**data)

    @pytest.fixture
    def downloader(self, configuration: Configuration) -> Downloader:
        return Downloader(configuration=configuration)

    @pytest.fixture
    def archiver(self, configuration: Configuration) -> Archiver:
        return Archiver(configuration=configuration)

    @pytest.fixture
    def client(self) -> Client:
        return Client()

    @pytest.fixture
    def bucket(self, configuration: Configuration, client: Client) -> Bucket:
        return client.bucket(
            bucket_name=configuration.destination_bucket.replace("gs://", "")
        )

    @pytest.fixture
    def destination_path(self, configuration: Configuration) -> str:
        return os.path.join(
            "service_alerts",
            "dt=2026-04-01",
            "hour=2026-04-01T00:00:00+00:00",
            "ts=2026-04-01T00:01:20+00:00",
            f"base64_url={configuration.base64_url()}",
            "feed",
        )

    @pytest.fixture
    def blob(self, bucket: Bucket, destination_path: str) -> Blob:
        return bucket.get_blob(blob_name=destination_path)

    @pytest.mark.vcr
    def test_archiver_stores_feed(
        self, downloader: Downloader, archiver: Archiver, blob: Blob
    ) -> None:
        archiver.save(result=downloader.get())
        assert json.loads(blob.metadata["PARTITIONED_ARTIFACT_METADATA"]) == {
            "filename": "feed",
            "ts": "2026-04-01T00:01:20+00:00",
            "config": {
                "extracted_at": "2026-04-01T00:00:00+00:00",
                "name": "Example",
                "url": "http://avl.yctd.org/RealTime/GTFS_ServiceAlerts.pb",
                "feed_type": "service_alerts",
                "schedule_url_for_validation": "http://www.yolobus.com/GTFS/google_transit.zip",
                "auth_query_params": {},
                "auth_headers": {},
            },
            "response_code": 200,
            "response_headers": {
                "Last-Modified": "Tue, 07 Apr 2026 22:36:11 GMT",
                "Date": "Tue, 07 Apr 2026 22:36:16 GMT",
                "Server": "Microsoft-IIS/10.0",
                "Content-Type": "application/x-protobuf",
                "X-Powered-By": "ASP.NET",
                "Accept-Ranges": "bytes",
                "Content-Length": "2960",
                "ETag": '"422da1efdec6dc1:0"',
            },
        }
