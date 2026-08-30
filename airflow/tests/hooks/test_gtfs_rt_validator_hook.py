import os

import pendulum
import pytest
from hooks.gtfs_rt_validator_hook import GTFSRTValidatorHook


class TestGTFSRTValidatorHook:
    @pytest.fixture
    def execution_date(self) -> pendulum.DateTime:
        return pendulum.DateTime.fromisoformat("2026-05-01T00:00:00+00:00")

    @pytest.fixture
    def config(self) -> dict[str, str | dict[str, str] | bool]:
        return {
            "extracted_at": "2026-04-30T03:00:00+00:00",
            "name": "Big Blue Bus Alerts",
            "url": "http://gtfs.bigbluebus.com/alerts.bin",
            "feed_type": "service_alerts",
            "schedule_url_for_validation": "https://www.bigbluebus.com/gtfs/current.zip",
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def hook(self) -> GTFSRTValidatorHook:
        return GTFSRTValidatorHook()

    @pytest.fixture
    def jar_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../../plugins/gtfs_rt_validator",
            )
        )

    @pytest.fixture
    def schedule_path(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)), "../fixtures/schedule.zip"
            )
        )

    @pytest.fixture
    def feed_directory(self) -> str:
        return os.path.realpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)), "../fixtures/feeds"
            )
        )

    @pytest.fixture
    def feed_paths(self, feed_directory: str) -> str:
        return [
            os.path.join(feed_directory, "service_alerts.pb"),
            os.path.join(feed_directory, "service_alerts_2.pb"),
        ]

    def test_validator_1_0_0(self, execution_date: pendulum.DateTime):
        assert (
            GTFSRTValidatorHook().version(ts=execution_date.isoformat()).number
            == "1.0.0"
        )

    def test_validator_path(
        self,
        execution_date: pendulum.DateTime,
        hook: GTFSRTValidatorHook,
        jar_path: str,
    ):
        assert hook.version(ts=execution_date.isoformat()).path() == os.path.join(
            jar_path, "gtfs-realtime-validator-lib-1.0.0-20220223.003525-2.jar"
        )

    def test_run(
        self,
        hook: GTFSRTValidatorHook,
        execution_date: pendulum.DateTime,
        config: dict,
        schedule_path: str,
        feed_directory: str,
        feed_paths: str,
    ):
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
            ts=execution_date.isoformat(),
            config=config,
            schedule_path=schedule_path,
            feed_directory=feed_directory,
            feed_paths=feed_paths,
        )
        assert len(result.notices()) == 6
        assert result.notices()[0] == {
            "metadata": {
                "extract_ts": "2026-05-01T00:00:00+00:00",
                "extract_config": {
                    "extracted_at": "2026-04-30T03:00:00+00:00",
                    "name": "Big Blue Bus Alerts",
                    "url": "http://gtfs.bigbluebus.com/alerts.bin",
                    "feed_type": "service_alerts",
                    "schedule_url_for_validation": "https://www.bigbluebus.com/gtfs/current.zip",
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "gtfs_validator_version": "v1.0.0",
            },
            "errorMessage": {
                "messageId": 0,
                "gtfsRtFeedIterationModel": None,
                "validationRule": {
                    "errorId": "W008",
                    "severity": "WARNING",
                    "title": "Header timestamp is older than 65 seconds",
                    "errorDescription": "The data in a GTFS-realtime feed should always be less than one minute old",
                    "occurrenceSuffix": "old which is greater than the recommended age of 65 seconds",
                },
                "errorDetails": None,
            },
            "occurrenceList": [
                {
                    "occurrenceId": 0,
                    "messageLogModel": None,
                    "prefix": result.notices()[0]["occurrenceList"][0]["prefix"],
                }
            ],
        }
