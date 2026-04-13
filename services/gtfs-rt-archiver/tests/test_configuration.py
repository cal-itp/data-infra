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
    def published_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-01T00:01:20.45+00:00")

    @pytest.fixture
    def current_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-07T00:01:23.45+00:00")

    @pytest.fixture
    def url(self) -> str:
        return "http://example.com"

    @pytest.fixture
    def data(self, published_time: datetime, current_time: datetime, url: str) -> dict:
        return {
            "published_time": published_time,
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
        }

    @pytest.fixture
    def secret_headers_data(self, published_time: datetime, current_time: datetime, url: str) -> dict:
        return {
            "published_time": published_time,
            "current_time": current_time,
            "auth_headers": {"authorization": "API_KEY"},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
        }

    @pytest.fixture
    def secret_query_params_data(self, published_time: datetime, current_time: datetime, url: str) -> dict:
        return {
            "published_time": published_time,
            "current_time": current_time,
            "auth_headers": {},
            "auth_query_params": {"api_key": "API_KEY"},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": url,
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
            **secret_headers_data
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
            **secret_query_params_data
        )

    def test_resolves_dt(self, configuration: Configuration) -> None:
        assert configuration.dt() == "2026-04-01"

    def test_resolves_hour(self, configuration: Configuration) -> None:
        assert configuration.hour() == "2026-04-01T00:00:00+00:00"

    def test_resolves_ts(self, configuration: Configuration) -> None:
        assert configuration.ts() == "2026-04-01T00:01:20+00:00"

    def test_base64_encodes_url(self, configuration: Configuration) -> None:
        assert configuration.base64_url() == "aHR0cDovL2V4YW1wbGUuY29t"

    def test_builds_destination_path(self, configuration: Configuration) -> None:
        assert configuration.destination_path() == os.path.join(
            "vehicle_positions",
            "dt=2026-04-01",
            "hour=2026-04-01T00:00:00+00:00",
            "ts=2026-04-01T00:01:20+00:00",
            "base64_url=aHR0cDovL2V4YW1wbGUuY29t",
            "feed",
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
        }
