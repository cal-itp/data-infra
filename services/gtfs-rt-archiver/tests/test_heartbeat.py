import json
from datetime import datetime

import pytest
from gtfs_rt_archiver.heartbeat import HIGH_FREQUENCY_COHORT, Heartbeat
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


class TestHeartbeatCohort:
    """The high-frequency cohort filter (issue #5566).

    These patch download_configs rather than replaying a cassette, so no new
    recordings are needed and the cases stay readable.
    """

    TRIP_UPDATES = {"name": "SLO Trip Updates", "feed_type": "trip_updates"}
    VEHICLE_POSITIONS = {
        "name": "Big Blue Bus VehiclePositions",
        "feed_type": "vehicle_positions",
    }
    SERVICE_ALERTS = {"name": "SLO Alerts", "feed_type": "service_alerts"}

    @pytest.fixture
    def publish_time(self) -> datetime:
        return datetime.fromisoformat("2025-06-02T00:01:23.45+00:00")

    @pytest.fixture
    def heartbeat(self, mocker: MockerFixture, publish_time: datetime) -> Heartbeat:
        heartbeat = Heartbeat(
            # 00:01:23 is deliberately off the 5-minute service-alert boundary, so
            # any alert that appears did so because the cohort bypassed the throttle.
            data=json.dumps({"batch_at": "2025-06-02T00:01:23+00:00"}),
            publish_time=publish_time,
            message_id="1",
        )
        mocker.patch.object(
            heartbeat,
            "download_configs",
            return_value=[
                self.TRIP_UPDATES,
                self.VEHICLE_POSITIONS,
                self.SERVICE_ALERTS,
            ],
        )
        return heartbeat

    @staticmethod
    def published_names(heartbeat: Heartbeat) -> list[str]:
        return [json.loads(message)["name"] for message in heartbeat.messages()]

    @pytest.mark.parametrize(
        ("cohort_env", "expected"),
        [
            # Absent: no filtering at all. This is the production heartbeat, and
            # the service-alert throttle still applies, so alerts are excluded.
            (None, ["SLO Trip Updates", "Big Blue Bus VehiclePositions"]),
            # Present but empty: fail closed. Treating this as "no filter" would
            # fan every feed out on the high-frequency clock.
            ("[]", []),
            ('["Big Blue Bus VehiclePositions"]', ["Big Blue Bus VehiclePositions"]),
            ('["big blue bus vehiclepositions"]', ["Big Blue Bus VehiclePositions"]),
            (
                '["  Big  Blue Bus VehiclePositions "]',
                ["Big Blue Bus VehiclePositions"],
            ),
            # A typo or an Airtable rename selects nothing rather than everything.
            ('["Nonexistent Feed"]', []),
        ],
    )
    def test_cohort_filters_messages(
        self,
        monkeypatch: pytest.MonkeyPatch,
        heartbeat: Heartbeat,
        cohort_env: str,
        expected: list[str],
    ) -> None:
        if cohort_env is None:
            monkeypatch.delenv(HIGH_FREQUENCY_COHORT, raising=False)
        else:
            monkeypatch.setenv(HIGH_FREQUENCY_COHORT, cohort_env)

        assert self.published_names(heartbeat) == expected

    def test_cohort_bypasses_service_alert_throttle(
        self, monkeypatch: pytest.MonkeyPatch, heartbeat: Heartbeat
    ) -> None:
        # The 5-minute throttle assumes batch times land on 20-second boundaries,
        # which the high-frequency clock does not honor.
        monkeypatch.setenv(HIGH_FREQUENCY_COHORT, '["SLO Alerts"]')

        assert self.published_names(heartbeat) == ["SLO Alerts"]

    def test_cohort_stamps_batch_at(
        self, monkeypatch: pytest.MonkeyPatch, heartbeat: Heartbeat
    ) -> None:
        monkeypatch.setenv(HIGH_FREQUENCY_COHORT, '["Big Blue Bus VehiclePositions"]')

        payload = json.loads(heartbeat.messages()[0])
        assert payload["batch_at"] == "2025-06-02T00:01:23+00:00"

    def test_production_messages_omit_batch_at(
        self, monkeypatch: pytest.MonkeyPatch, heartbeat: Heartbeat
    ) -> None:
        # Guards the production message shape: batch_at must not leak into the
        # standard fan-out, or every production path would change.
        monkeypatch.delenv(HIGH_FREQUENCY_COHORT, raising=False)

        for message in heartbeat.messages():
            assert "batch_at" not in json.loads(message)

    def test_limit_applies_after_cohort_filter(
        self,
        monkeypatch: pytest.MonkeyPatch,
        mocker: MockerFixture,
        publish_time: datetime,
    ) -> None:
        monkeypatch.setenv(
            HIGH_FREQUENCY_COHORT,
            '["SLO Trip Updates", "Big Blue Bus VehiclePositions"]',
        )
        heartbeat = Heartbeat(
            data=json.dumps({"batch_at": "2025-06-02T00:01:23+00:00"}),
            publish_time=publish_time,
            message_id="1",
            limit=1,
        )
        mocker.patch.object(
            heartbeat,
            "download_configs",
            return_value=[self.TRIP_UPDATES, self.VEHICLE_POSITIONS],
        )

        assert self.published_names(heartbeat) == ["SLO Trip Updates"]
