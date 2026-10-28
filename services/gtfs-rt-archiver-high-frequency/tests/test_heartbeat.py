import json
from datetime import datetime

import pytest
from gtfs_rt_archiver.heartbeat import Heartbeat
from pytest_mock import MockerFixture


class FakePublisher:
    def publish(self, path: str, data: bytes = b""):
        print(f"path={path} data={data}")
        return (path, data)


class TestHeartbeat:
    @pytest.fixture
    def publish_time(self) -> datetime:
        return datetime.fromisoformat("2025-06-02T00:01:23.45+00:00")

    @pytest.fixture
    def data(self) -> dict:
        return {
            "batch_at": datetime.fromisoformat("2025-06-02T00:01:20+00:00").isoformat()
        }

    @pytest.fixture
    def heartbeat(self, data: dict, publish_time: datetime) -> Heartbeat:
        return Heartbeat(
            data=json.dumps(data), publish_time=publish_time, message_id="1", limit=1
        )

    @pytest.mark.vcr
    def test_heartbeat_reads_download_configs(self, heartbeat: Heartbeat) -> None:
        assert len(heartbeat.messages()) == 1
        assert json.loads(heartbeat.messages()[0]) == {
            "extracted_at": "2025-06-02T00:00:00+00:00",
            "feed_type": "trip_updates",
            "name": "SLO Trip Updates",
            "schedule_url_for_validation": "http://data.peaktransit.com/staticgtfs/1/gtfs.zip",
            "url": "http://data.peaktransit.com/gtfsrt/1/TripUpdate.pb",
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.mark.vcr
    def test_heartbeat_enqueues_message(
        self, mocker: MockerFixture, heartbeat: Heartbeat
    ) -> None:
        fake_publisher = FakePublisher()
        mocker.spy(fake_publisher, "publish")
        heartbeat.run(publisher=fake_publisher)
        fake_publisher.publish.assert_called_with(
            "projects/cal-itp-data-infra-staging/topics/example",
            data=heartbeat.messages()[0],
        )

    def test_should_publish_non_service_alerts(self, heartbeat: Heartbeat) -> None:
        assert heartbeat.should_publish("trip_updates")
        assert heartbeat.should_publish("vehicle_positions")

    @pytest.mark.parametrize(
        ("batch_at", "expected"),
        [
            ("2025-06-02T00:00:00+00:00", True),
            ("2025-06-02T00:00:20+00:00", False),
            ("2025-06-02T00:00:40+00:00", False),
            ("2025-06-02T00:01:00+00:00", False),
            ("2025-06-02T00:05:00+00:00", True),
            ("2025-06-02T00:10:00+00:00", True),
        ],
    )
    def test_should_publish_service_alerts(
        self,
        batch_at: str,
        expected: bool,
        publish_time: datetime,
    ) -> None:
        heartbeat = Heartbeat(
            data=json.dumps({"batch_at": batch_at}),
            publish_time=publish_time,
            message_id="1",
        )

        assert heartbeat.should_publish("service_alerts") is expected
