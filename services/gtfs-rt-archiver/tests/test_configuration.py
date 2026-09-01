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

    def test_json_omits_batch_at(self, data: dict) -> None:
        # json() is embedded in PARTITIONED_ARTIFACT_METADATA and round-tripped
        # through strict consumers, so its shape must not change.
        configuration = Configuration.resolve(
            batch_at="2026-04-01T00:01:23+00:00", **data
        )

        assert "batch_at" not in configuration.json()


class TestConfigurationBatchAt:
    """Timestamps when the high-frequency clock supplies batch_at (issue #5566).

    Without batch_at every accessor must behave exactly as before -- that is the
    regression guard protecting production object paths.
    """

    @pytest.fixture
    def publish_time(self) -> datetime:
        return datetime.fromisoformat("2026-04-01T00:01:20.45+00:00")

    @pytest.fixture
    def data(self, publish_time: datetime) -> dict:
        return {
            "publish_time": publish_time,
            "auth_headers": {},
            "auth_query_params": {},
            "extracted_at": "2026-04-01T00:00:00+00:00",
            "feed_type": "vehicle_positions",
            "name": "Example",
            "schedule_url_for_validation": "http://example.com/gtfs.zip",
            "url": "http://example.com",
            "computed": False,
        }

    def test_ts_is_exact_and_unfloored(self, data: dict) -> None:
        # 23 is not a multiple of 20; the legacy path would floor it to 20.
        configuration = Configuration.resolve(
            batch_at="2026-04-01T00:01:23+00:00", **data
        )

        assert configuration.ts() == "2026-04-01T00:01:23+00:00"

    def test_explicit_none_batch_at_keeps_legacy_floor(self, data: dict) -> None:
        configuration = Configuration.resolve(batch_at=None, **data)

        assert configuration.ts() == "2026-04-01T00:01:20+00:00"

    def test_dt_hour_and_ts_agree_across_an_hour_boundary(self) -> None:
        # Published at 12:59:59 for a tick batched at 13:00:02. If hour() still
        # came from publish_time we would write hour=12:00.../ts=13:00:02, an
        # inconsistency the RT parser cross-checks and rejects.
        configuration = Configuration.resolve(
            publish_time=datetime.fromisoformat("2026-04-01T12:59:59.9+00:00"),
            batch_at="2026-04-01T13:00:02+00:00",
            auth_headers={},
            auth_query_params={},
            extracted_at="2026-04-01T00:00:00+00:00",
            feed_type="vehicle_positions",
            name="Example",
            schedule_url_for_validation="http://example.com/gtfs.zip",
            url="http://example.com",
            computed=False,
        )

        assert configuration.dt() == "2026-04-01"
        assert configuration.hour() == "2026-04-01T13:00:00+00:00"
        assert configuration.ts() == "2026-04-01T13:00:02+00:00"

    def test_three_second_grid_yields_distinct_prefixes(self, data: dict) -> None:
        """This is the bug in #5566, encoded as a test.

        Twenty ticks on a 3-second grid must produce twenty distinct object
        paths. Relying on publish_time instead collapses them into three, which
        is the silent 85% data loss the cohort feature would otherwise cause.
        """
        base = datetime.fromisoformat("2026-04-01T00:01:00+00:00")

        gridded = {
            Configuration.resolve(
                batch_at=base.replace(second=3 * tick).isoformat(),
                **data,
            ).destination_prefix()
            for tick in range(20)
        }
        assert len(gridded) == 20

        floored = {
            Configuration.resolve(
                **(data | {"publish_time": base.replace(second=3 * tick)}),
            ).destination_prefix()
            for tick in range(20)
        }
        assert len(floored) == 3
