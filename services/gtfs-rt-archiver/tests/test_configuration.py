import os
from datetime import datetime

import pytest
from gtfs_rt_archiver.configuration import HEADERS, Configuration


class MockSecret:
    def __init__(self, project_id: str, name: str, value: any) -> None:
        self.project_id: str = project_id
        self.name: str = name
        self.value: any = value

    def get(self) -> any:
        return self.value


class TestConfiguration:
    @pytest.fixture
    def publish_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-01T00:01:20.45+00:00")

    @pytest.fixture
    def current_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-07T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://example.com"

    @pytest.fixture
    def data(self, publish_time: datetime, current_time: datetime, url: str) -> dict:
        return {
            "publish_time": publish_time,
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
            "computed": False,
        }

    @pytest.fixture
    def secret_headers_data(
        self, publish_time: datetime, current_time: datetime, url: str
    ) -> dict:
        return {
            "publish_time": publish_time,
            "current_time": current_time,
            "auth_headers": {"authorization": "API_KEY"},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
            "computed": False,
        }

    @pytest.fixture
    def secret_query_params_data(
        self, publish_time: datetime, current_time: datetime, url: str
    ) -> dict:
        return {
            "publish_time": publish_time,
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {"api_key": "API_KEY"},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
            "computed": False,
        }

    @pytest.fixture
    def configuration(self, current_time: datetime, data: dict) -> Configuration:
        return Configuration.resolve(**data)

    @pytest.fixture
    def secret_header_configuration(
        self, current_time: datetime, secret_headers_data: dict
    ) -> Configuration:
        return Configuration.resolve(
            secret_resolver=lambda project_id, name: MockSecret(
                project_id=project_id,
                name=name,
                value="very-secret" if name == "API_KEY" else None,
            ),
            **secret_headers_data,
        )

    @pytest.fixture
    def secret_query_param_configuration(
        self, current_time: datetime, secret_query_params_data: dict
    ) -> Configuration:
        return Configuration.resolve(
            secret_resolver=lambda project_id, name: MockSecret(
                project_id=project_id,
                name=name,
                value="very-secret" if name == "API_KEY" else None,
            ),
            **secret_query_params_data,
        )

    def test_resolves_dt(self, configuration: Configuration) -> None:
        assert configuration.dt() == "2026-04-01"

    def test_resolves_hour(self, configuration: Configuration) -> None:
        assert configuration.hour() == "2026-04-01T00:00:00+00:00"

    def test_use_ts_floor_defaults_true(self, configuration: Configuration) -> None:
        assert configuration.use_ts_floor is True

    def test_resolves_ts(self, configuration: Configuration) -> None:
        assert configuration.ts() == "2026-04-01T00:01:20+00:00"

    def test_base64_encodes_url(self, configuration: Configuration) -> None:
        assert configuration.base64_url() == "aHR0cDovL2V4YW1wbGUuY29t"

    def test_builds_destination_prefix(self, configuration: Configuration) -> None:
        assert configuration.destination_prefix() == os.path.join(
            "vehicle_positions",
            "dt=2026-04-01",
            "hour=2026-04-01T00:00:00+00:00",
            "ts=2026-04-01T00:01:20+00:00",
            "base64_url=aHR0cDovL2V4YW1wbGUuY29t",
        )

    def test_empty_headers(self, configuration: Configuration) -> None:
        assert configuration.headers() == HEADERS | {}

    def test_resolved_headers(self, secret_header_configuration: Configuration) -> None:
        assert secret_header_configuration.headers() == HEADERS | {
            "authorization": "very-secret"
        }

    def test_resolved_query_params(
        self, secret_query_param_configuration: Configuration
    ) -> None:
        assert secret_query_param_configuration.params() == {"api_key": "very-secret"}

    def test_json(self, configuration: Configuration) -> None:
        assert configuration.json() == {
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "name": "Example",
            "url": "http://example.com",
            "feed_type": "vehicle_positions",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }


class TestConfigurationFloorOff:
    """ts() with the floor disabled (issue #5566).

    The high-frequency archiver sets CALITP_GTFS_RT_USE_TS_FLOOR=false so that
    polling faster than every 20 seconds gives each sample its own object path
    instead of silently overwriting (the default, floored behavior is covered by
    TestConfiguration). The env var is flipped once in the fixture, so the
    individual tests don't each have to.
    """

    @pytest.fixture
    def configuration(self, monkeypatch: pytest.MonkeyPatch) -> Configuration:
        monkeypatch.setenv("CALITP_GTFS_RT_USE_TS_FLOOR", "false")
        # 23.45s is neither on the 20s grid nor microsecond-zeroed, so the floored
        # path (see TestConfiguration) would drop both; here they must survive.
        return Configuration.resolve(
            publish_time=datetime.fromisoformat("2026-04-01T00:01:23.45+00:00"),
            auth_headers={},
            auth_query_params={},
            extracted_at="2026-04-01T00:00:00+00:00",
            feed_type="vehicle_positions",
            name="Example",
            schedule_url_for_validation="http://example.com/gtfs.zip",
            url="http://example.com",
            computed=False,
        )

    def test_use_ts_floor_resolves_false(self, configuration: Configuration) -> None:
        assert configuration.use_ts_floor is False

    def test_ts_keeps_full_resolution_publish_time(
        self, configuration: Configuration
    ) -> None:
        assert configuration.ts() == "2026-04-01T00:01:23.450000+00:00"

    def test_destination_prefix_uses_unfloored_ts(
        self, configuration: Configuration
    ) -> None:
        # The unfloored ts is what gives every sub-20s poll a distinct path.
        assert configuration.destination_prefix() == os.path.join(
            "vehicle_positions",
            "dt=2026-04-01",
            "hour=2026-04-01T00:00:00+00:00",
            "ts=2026-04-01T00:01:23.450000+00:00",
            "base64_url=aHR0cDovL2V4YW1wbGUuY29t",
        )
