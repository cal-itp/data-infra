import json
import os
from datetime import datetime

import pytest
from google.cloud.storage import Blob, Bucket, Client
from gtfs_rt_archiver.configuration import Configuration
from gtfs_rt_archiver.service import Service


class TestService:
    @pytest.fixture
    def publish_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-01T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://avl.yctd.org/RealTime/GTFS_ServiceAlerts.pb"

    @pytest.fixture
    def data(self, url: str) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "service_alerts",
            "name": "Example",
            "schedule_url_for_validation": "http://www.yolobus.com/GTFS/google_transit.zip",
            "url": url,
        }

    @pytest.fixture
    def configuration(self, data: dict, publish_time: datetime) -> Configuration:
        return Configuration.resolve(publish_time=publish_time.isoformat(), **data)

    @pytest.fixture
    def service(self, data: dict, publish_time: datetime) -> Service:
        return Service(data=json.dumps(data), publish_time=publish_time, message_id="1")

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
    def test_service_downloads_blob(self, service: Service, blob: Blob) -> None:
        service.run()
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
                "Last-Modified": "Tue, 07 Apr 2026 22:36:26 GMT",
                "Date": "Tue, 07 Apr 2026 22:36:27 GMT",
                "Server": "Microsoft-IIS/10.0",
                "Content-Type": "application/x-protobuf",
                "X-Powered-By": "ASP.NET",
                "Accept-Ranges": "bytes",
                "Content-Length": "2960",
                "ETag": 'W/"556a91f8dec6dc1:0"',
            },
        }
