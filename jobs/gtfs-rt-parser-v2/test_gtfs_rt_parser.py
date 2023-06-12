import pendulum
import pytest
from calitp_data_infra.storage import (  # type: ignore
    GTFSDownloadConfig,
    GTFSFeedType,
    GTFSRTFeedExtract,
)
from pydantic import ValidationError

# isort doesn't realize this is a local file when run from the top of the project
# the actual fix would be to make gtfs_rt_parser a proper module that is executed with -m
from gtfs_rt_parser import (  # isort:skip
    RTFileProcessingOutcome,
    RTHourlyAggregation,
    RTProcessingStep,
)


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
