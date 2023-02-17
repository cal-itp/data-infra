import pendulum
import pytest
from calitp_data_infra.storage import (  # type: ignore
    GTFSDownloadConfig,
    GTFSFeedType,
    GTFSRTFeedExtract,
)
from gtfs_rt_parser import (
    RTFileProcessingOutcome,
    RTHourlyAggregation,
    RTProcessingStep,
)
from pydantic import ValidationError


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
            feed_type=GTFSFeedType.vehicle_positions,
            hour=extract.ts.replace(minute=0, second=0, microsecond=0),
            base64_url=extract.base64_url,
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
