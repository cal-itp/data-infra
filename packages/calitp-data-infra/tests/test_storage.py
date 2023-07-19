import pendulum
import pytest
from calitp_data_infra.storage import GTFSDownloadConfig
from pydantic import ValidationError


def test_gtfs_download_config() -> None:
    GTFSDownloadConfig(
        extracted_at=pendulum.now(),
        url="https://google.com",
        feed_type="schedule",
    )

    with pytest.raises(ValidationError):
        GTFSDownloadConfig(
            extracted_at=pendulum.now(),
            url="https://google.com",
            feed_type="some invalid type",
        )


def test_gtfs_download_config_build_request() -> None:
    GTFSDownloadConfig(
        extracted_at=pendulum.now(),
        url="https://google.com",
        feed_type="schedule",
    ).build_request(auth_dict={})
