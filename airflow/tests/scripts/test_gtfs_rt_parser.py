import pytest
from calitp_data_infra.storage import GTFSFeedType
from scripts.gtfs_rt_parser import app
from typer.testing import CliRunner


class TestGtfsRtParser:
    @pytest.fixture
    def runner(self) -> CliRunner:
        return CliRunner()

    def test_feed_type_strings(self):
        assert f"{GTFSFeedType.vehicle_positions.value}" == "vehicle_positions"

    def test_no_vehicle_positions_for_date(self, runner):
        base64url = (
            "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ"
        )
        result = runner.invoke(
            app,
            [
                "parse",
                "vehicle_positions",
                "2022-09-14T18:00:00",
                "--base64url",
                base64url,
            ],
        )
        assert result.exit_code == 0
        assert "0 vehicle_positions files in 0 aggregations to process" in result.stdout
        assert f"url filter applied, only processing {base64url}" in result.stdout
        assert "outcomes" not in result.stdout

    def test_no_vehicle_positions_for_url(self, runner):
        result = runner.invoke(
            app,
            [
                "parse",
                "vehicle_positions",
                "2024-09-14T18:00:00",
                "--base64url",
                "nope",
            ],
        )
        assert result.exit_code == 0
        assert (
            "found 0 vehicle_positions files in 0 aggregations to process"
            in result.stdout
        )
        assert "url filter applied, only processing nope" in result.stdout
        assert "outcomes" not in result.stdout

    def test_trip_updates(self, runner):
        base64url = (
            "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1TQQ=="
        )
        result = runner.invoke(
            app,
            [
                "parse",
                "trip_updates",
                "2024-10-22T18:00:00",
                "--base64url",
                base64url,
            ],
        )
        assert result.exit_code == 0
        assert (
            "calitp-staging-pytest-parsed/trip_updates_outcomes/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00/trip_updates_aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1TQQ==.jsonl"
            in result.stdout
        )
        assert (
            "found 180 trip_updates files in 1 aggregations to process" in result.stdout
        )
        assert f"url filter applied, only processing {base64url}" in result.stdout
        assert "writing 660 lines" in result.stdout
        assert "calitp-staging-pytest-parsed" in result.stdout
        assert "saving 180 outcomes" in result.stdout

    def test_service_alerts(self, runner):
        base64url = (
            "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3NlcnZpY2VhbGVydHM_YWdlbmN5PUFN"
        )
        result = runner.invoke(
            app,
            [
                "parse",
                "service_alerts",
                "2024-10-22T18:00:00",
                "--base64url",
                base64url,
            ],
        )
        assert result.exit_code == 0
        assert (
            "found 180 service_alerts files in 1 aggregations to process"
            in result.stdout
        )
        assert f"url filter applied, only processing {base64url}" in result.stdout
        assert "writing 153 lines" in result.stdout
        assert (
            "calitp-staging-pytest-parsed/service_alerts_outcomes/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00/service_alerts_aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3NlcnZpY2VhbGVydHM_YWdlbmN5PUFN.jsonl"
            in result.stdout
        )
        assert "saving 180 outcomes" in result.stdout

    def test_validation(self, runner):
        base64url = "aHR0cHM6Ly9hcGkuZ29zd2lmdC5seS9yZWFsLXRpbWUvbWVuZG9jaW5vL2d0ZnMtcnQtdHJpcC11cGRhdGVz"
        result = runner.invoke(
            app,
            [
                "validate",
                "trip_updates",
                "2024-08-28T19:00:00",
                "--base64url",
                base64url,
            ],
        )
        assert result.exit_code == 0
        assert (
            "calitp-staging-pytest-validation/trip_updates_validation_outcomes/dt=2024-08-28/hour=2024-08-28T19:00:00+00:00/trip_updates_aHR0cHM6Ly9hcGkuZ29zd2lmdC5seS9yZWFsLXRpbWUvbWVuZG9jaW5vL2d0ZnMtcnQtdHJpcC11cGRhdGVz.jsonl"
            in result.stdout
        )
        assert (
            "found 180 trip_updates files in 1 aggregations to process" in result.stdout
        )
        assert "validating" in result.stdout
        assert "executing rt_validator" in result.stdout
        assert "writing 180 lines" in result.stdout
        assert "saving 180 outcomes" in result.stdout

    def test_no_recent_schedule_for_vehicle_positions_on_validation(self, runner):
        base64url = (
            "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ"
        )
        result = runner.invoke(
            app,
            [
                "validate",
                "vehicle_positions",
                "2024-09-14T18:00:00",
                "--base64url",
                base64url,
            ],
        )
        assert result.exit_code == 0
        assert (
            "calitp-staging-pytest/vehicle_positions/dt=2024-09-14/hour=2024-09-14T18:00:00+00:00/ts=2024-09-14T18:00:00+00:00/base64_url=aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ/feed"
            in result.stdout
        )
        assert (
            "found 180 vehicle_positions files in 1 aggregations to process"
            in result.stdout
        )
        assert f"url filter applied, only processing {base64url}" in result.stdout
        assert "no schedule data found" in result.stdout
        assert "no recent schedule data found" in result.stdout
        assert (
            "calitp-staging-pytest-validation/vehicle_positions_validation_outcomes/dt=2024-09-14/hour=2024-09-14T18:00:00+00:00/vehicle_positions_aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ.jsonl"
            in result.stdout
        )
        assert "saving 180 outcomes" in result.stdout

    def test_no_output_file_for_vehicle_positions_on_validation(self, runner):
        result = runner.invoke(
            app,
            [
                "validate",
                "vehicle_positions",
                "2024-10-17T00:00:00",
                "--limit",
                3,
                "--verbose",
            ],
        )
        assert result.exit_code == 0
        assert (
            "/vehicle_positions/dt=2024-10-17/hour=2024-10-17T00:00:00+00:00"
            in result.stdout
        )
        assert (
            "found 23937 vehicle_positions files in 133 aggregations to process"
            in result.stdout
        )
        assert "limit of 3 feeds was set" in result.stdout
        assert "validating" in result.stdout
        assert "executing rt_validator" in result.stdout
        assert "writing 180 lines" in result.stdout
        assert "saving 540 outcomes" in result.stdout
