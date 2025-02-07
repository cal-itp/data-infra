import pendulum
import pytest
from calitp_data_infra.storage import GTFSDownloadConfig, make_name_bq_safe
from pydantic.v1 import ValidationError


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


def test_make_name_bq_safe() -> None:
    assert make_name_bq_safe("123NAME") == "_123name"
    assert make_name_bq_safe(123) == "_123"
    assert make_name_bq_safe("Name") == "name"
    assert make_name_bq_safe("# of Things") == "__of_things"
