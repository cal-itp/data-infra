import pendulum
import pytest
from calitp_data_infra.storage import (  # type: ignore
    GTFSDownloadConfig,
    GTFSFeedType,
    GTFSRTFeedExtract,
)
from pydantic import ValidationError
from typer.testing import CliRunner

# isort doesn't realize this is a local file when run from the top of the project
# the actual fix would be to make gtfs_rt_parser a proper module that is executed with -m
from gtfs_rt_parser import (  # isort:skip
    RTFileProcessingOutcome,
    RTHourlyAggregation,
    RTProcessingStep,
    app,
)

runner = CliRunner()


def test_rt_file_processing_outcome_construction() -> None:
    extract = GTFSRTFeedExtract(
        filename="feed.proto",
        ts=pendulum.now(),
        config=GTFSDownloadConfig(
            url="https://google.com",
            feed_type=GTFSFeedType.vehicle_positions,
        ),
        response_code=200,
    )

    RTFileProcessingOutcome(
        step=RTProcessingStep.parse,
        success=True,
        extract=extract,
        aggregation=RTHourlyAggregation(
            filename="vehicle_positions.jsonl.gz",
            step=RTProcessingStep.parse,
            first_extract=extract,
            extracts=[
                extract,
            ],
        ),
    )

    with pytest.raises(ValidationError):
        RTFileProcessingOutcome(
            success=True,
            extract=extract,
        )


def test_vehicle_positions():
    base64url = "aHR0cHM6Ly9tdnNodXR0bGUucmlkZXN5c3RlbXMubmV0L3N1YnNjcmlwdGlvbnMvZ3Rmc3J0L3ZlaGljbGVzLmFzaHg="
    result = runner.invoke(
        app,
        ["parse", "vehicle_positions", "2024-10-22T18:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/vehicle_positions/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00"
        in result.stdout
    )
    assert "4786 vehicle_positions files in 139 aggregations" in result.stdout

    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "writing 28 lines" in result.stdout
    assert "test-calitp-gtfs-rt-parsed" in result.stdout
    assert "saving 40 outcomes" in result.stdout


def test_no_vehicle_positions_for_date():
    base64url = (
        "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ"
    )
    result = runner.invoke(
        app,
        ["parse", "vehicle_positions", "2022-09-14T18:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert "0 vehicle_positions files in 0 aggregations" in result.stdout
    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "outcomes" not in result.stdout


def test_no_vehicle_positions_for_url():
    result = runner.invoke(
        app,
        ["parse", "vehicle_positions", "2024-09-14T18:00:00", "--base64url", "nope"],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert "found 5158 vehicle_positions files in 136 aggregations" in result.stdout
    assert "url filter applied, only processing nope" in result.stdout
    assert "outcomes" not in result.stdout


def test_no_records_for_url_vehicle_positions_on_date():
    base64url = (
        "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3ZlaGljbGVwb3NpdGlvbnM_YWdlbmN5PVNJ"
    )
    result = runner.invoke(
        app,
        ["parse", "vehicle_positions", "2024-09-14T18:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert "found 5158 vehicle_positions files in 136 aggregations" in result.stdout
    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "WARNING: no records at all" in result.stdout
    assert "saving 38 outcomes" in result.stdout


def test_trip_updates():
    base64url = "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3RyaXB1cGRhdGVzP2FnZW5jeT1TQQ=="
    result = runner.invoke(
        app,
        ["parse", "trip_updates", "2024-10-22T18:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/trip_updates/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00"
        in result.stdout
    )
    assert "4489 trip_updates files in 132 aggregations" in result.stdout

    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "writing 180 lines" in result.stdout
    assert "test-calitp-gtfs-rt-parsed" in result.stdout
    assert "saving 49 outcomes" in result.stdout


def test_service_alerts():
    base64url = "aHR0cHM6Ly9hcGkuNTExLm9yZy90cmFuc2l0L3NlcnZpY2VhbGVydHM_YWdlbmN5PUFN"
    result = runner.invoke(
        app,
        ["parse", "service_alerts", "2024-10-22T18:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/service_alerts/dt=2024-10-22/hour=2024-10-22T18:00:00+00:00"
        in result.stdout
    )
    assert "4569 service_alerts files in 131 aggregations" in result.stdout

    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "writing 24 lines" in result.stdout
    assert "test-calitp-gtfs-rt-parsed" in result.stdout
    assert "saving 30 outcomes" in result.stdout


def test_validation():
    base64url = "aHR0cHM6Ly9hcGkuZ29zd2lmdC5seS9yZWFsLXRpbWUvbWVuZG9jaW5vL2d0ZnMtcnQtdHJpcC11cGRhdGVz"
    result = runner.invoke(
        app,
        ["validate", "trip_updates", "2024-08-28T19:00:00", "--base64url", base64url],
        catch_exceptions=False,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/trip_updates/dt=2024-08-28/hour=2024-08-28T19:00:00+00:00"
        in result.stdout
    )
    assert "3269 trip_updates files in 125 aggregations" in result.stdout
    assert "Fetching gtfs schedule data" in result.stdout
    assert "validating" in result.stdout
    assert "executing rt_validator" in result.stdout
    assert "writing 50 lines" in result.stdout
    assert "saving 30 outcomes" in result.stdout


def test_no_recent_schedule_for_vehicle_positions_on_validation():
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
        catch_exceptions=True,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/vehicle_positions/dt=2024-09-14/hour=2024-09-14T18:00:00+00:00"
        in result.stdout
    )
    assert "5158 vehicle_positions files in 136 aggregations" in result.stdout
    assert f"url filter applied, only processing {base64url}" in result.stdout
    assert "no schedule data found" in result.stdout
    assert "test-calitp-gtfs-rt-validation" in result.stdout
    assert "saving 38 outcomes" in result.stdout


def test_no_output_file_for_vehicle_positions_on_validation():
    # "WARNING: no validation output file found" generates the log "[Errno 2] No such file or directory"
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
        catch_exceptions=True,
    )
    assert result.exit_code == 0
    assert (
        "test-calitp-gtfs-rt-raw-v2/vehicle_positions/dt=2024-10-17/hour=2024-10-17T00:00:00+00:00"
        in result.stdout
    )
    assert "5487 vehicle_positions files in 139 aggregations" in result.stdout
    assert "limit of 3 feeds was set" in result.stdout
    assert "WARNING: no validation output file found" in result.stdout
    assert "saving 122 outcomes" in result.stdout
