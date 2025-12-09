import os

import pendulum
import pytest
from hooks.gtfs_validator_hook import GTFSValidatorHook


class TestGTFSValidatorHook:
    @pytest.fixture
    def date(self) -> pendulum.DateTime:
        return pendulum.datetime(2025, 11, 15)

    @pytest.fixture
    def hook(self, date: pendulum.DateTime) -> GTFSValidatorHook:
        return GTFSValidatorHook(date=date)

    @pytest.fixture
    def jar_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../../plugins/gtfs_validator",
            )
        )

    def test_validator_5_0_0(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2025, 11, 15)).version().number
            == "5.0.0"
        )

    def test_validator_4_2_0(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2024, 3, 26)).version().number
            == "4.2.0"
        )

    def test_validator_4_1_0(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2024, 1, 19)).version().number
            == "4.1.0"
        )

    def test_validator_4_0_0(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2023, 8, 30)).version().number
            == "4.0.0"
        )

    def test_validator_3_1_1(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2022, 11, 15)).version().number
            == "3.1.1"
        )

    def test_validator_2_0_0(self):
        assert (
            GTFSValidatorHook(date=pendulum.datetime(2022, 9, 14)).version().number
            == "2.0.0"
        )

    def test_validator_path(self, hook: GTFSValidatorHook, jar_path: str):
        assert hook.version().path() == os.path.join(
            jar_path, "gtfs-validator-5.0.0-cli.jar"
        )

    def test_run_with_unknown_file(
        self,
        hook: GTFSValidatorHook,
    ):
        fixture_schedule_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)), "../fixtures/schedule.zip"
            )
        )
        download_schedule_feed_results = {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-14T02:00:00+00:00",
                "feed_type": "schedule",
                "name": "Santa Ynez Mecatran Schedule",
                "schedule_url_for_validation": None,
                "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
            },
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-03T00:00:00+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "feed_type": "schedule",
                    "name": "Santa Ynez Mecatran Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "success": True,
        }

        result = hook.run(
            filename=fixture_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
        assert len(result.notices()) == 4
        assert result.notices()[-1] == {
            "metadata": {
                "extract_config": {
                    "extracted_at": "2025-11-14T02:00:00+00:00",
                    "name": "Santa Ynez Mecatran Schedule",
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "gtfs_validator_version": "v5.0.0",
            },
            "code": "unknown_file",
            "severity": "INFO",
            "totalNotices": 1,
            "sampleNotices": [{"filename": "route_directions.txt"}],
        }
        assert result.results() == {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-06-03T00:00:00+00:00",
                "config": {
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                    "name": "Santa Ynez Mecatran Schedule",
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "ts": "2025-11-15T00:00:00+00:00",
                "extract_config": {
                    "extracted_at": "2025-11-14T02:00:00+00:00",
                    "name": "Santa Ynez Mecatran Schedule",
                    "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "system_errors": {"notices": []},
                "validator_version": "v5.0.0",
            },
        }

    def test_run_with_one_empty_file(
        self,
        hook: GTFSValidatorHook,
    ):
        fixture_schedule_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/schedule-27.zip",
            )
        )
        download_schedule_feed_results = {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-11-12T02:00:00+00:00",
                "feed_type": "schedule",
                "name": "Fric and Frac Schedule",
                "schedule_url_for_validation": None,
                "url": "https://www.ips-systems.com/GTFS/Schedule/27",
            },
            "exception": None,
            "extract": {
                "filename": "schedule-27.zip",
                "ts": "2025-11-13T03:02:04.189504+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=schedule-27.zip",
                },
                "reconstructed": False,
            },
            "success": True,
        }

        result = hook.run(
            filename=fixture_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
        assert len(result.notices()) == 0
        assert result.results() == {
            "success": True,
            "exception": None,
            "extract": {
                "filename": "schedule-27.zip",
                "ts": "2025-11-13T03:02:04.189504+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=schedule-27.zip",
                },
                "reconstructed": False,
            },
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "ts": "2025-11-15T00:00:00+00:00",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-12T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "Fric and Frac Schedule",
                    "schedule_url_for_validation": None,
                    "url": "https://www.ips-systems.com/GTFS/Schedule/27",
                },
                "system_errors": {"notices": []},
                "validator_version": "v5.0.0",
            },
        }

    def test_run_unsupported_file(
        self,
        hook: GTFSValidatorHook,
    ):
        fixture_schedule_path = os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/bad-gtfs.zip",
            )
        )

        download_schedule_feed_results = {
            "backfilled": False,
            "config": {
                "auth_headers": {},
                "auth_query_params": {},
                "computed": False,
                "extracted_at": "2025-12-07T00:00:00+00:00",
                "feed_type": "schedule",
                "name": "San Joaquin Schedule",
                "schedule_url_for_validation": None,
                "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
            },
            "exception": None,
            "extract": {
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-12-07T00:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "San Joaquin Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                },
                "filename": "gtfs.zip",
                "reconstructed": False,
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "ts": "2025-12-07T00:00:00+00:00",
            },
            "success": True,
        }

        result = hook.run(
            filename=fixture_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
        assert len(result.notices()) == 0
        assert "returned non-zero exit status 255" in result.results()["exception"]

        partial_results = {
            "success": False,
            "extract": {
                "filename": "gtfs.zip",
                "ts": "2025-12-07T00:00:00+00:00",
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-12-07T00:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "San Joaquin Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                    "Content-Disposition": "attachment; filename=gtfs.zip",
                },
                "reconstructed": False,
            },
            "validation": {
                "filename": "validation_notices_v5-0-0.jsonl.gz",
                "ts": "2025-11-15T00:00:00+00:00",
                "extract_config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-12-07T00:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "San Joaquin Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                },
                "system_errors": {},
                "validator_version": "v5.0.0",
            },
        }
        assert partial_results.items() <= result.results().items()
