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
