import pytest
from hooks.download_config_hook import DownloadConfigHook
from requests.exceptions import SSLError

from airflow.exceptions import AirflowException


class TestDownloadConfigHook:
    @pytest.fixture
    def unauthenticated_download_config(self) -> dict:
        return {
            "auth_headers": {},
            "auth_query_params": {},
            "computed": False,
            "feed_type": "schedule",
            "name": "Santa Ynez Mecatran Schedule",
            "schedule_url_for_validation": None,
            "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
            "extracted_at": "2025-06-01T00:00:00+00:00",
        }

    @pytest.fixture
    def header_authenticated_download_config(self) -> dict:
        return {
            "extracted_at": "2025-11-14T02:00:00+00:00",
            "name": "Glendale Schedule",
            "url": "https://glendaleca.gov/Home/ShowDocument?id=29549",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {"Granicus-Auth": "Granicus-Auth"},
            "computed": False,
        }

    @pytest.fixture
    def query_authenticated_download_config(self) -> dict:
        return {
            "extracted_at": "2025-11-14T02:00:00+00:00",
            "name": "Bay Area 511 Treasure Island Ferry Schedule",
            "url": "https://api.511.org/transit/datafeeds?operator_id=TF",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {"api_key": "MTC_511_API_KEY"},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def not_found_download_config(self) -> dict:
        return {
            "extracted_at": "2025-11-14T02:00:00+00:00",
            "name": "Nopetown Schedule",
            "url": "https://httpbin.org/status/404",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def certificate_error_download_config(self) -> dict:
        return {
            "extracted_at": "2025-11-14T02:00:00+00:00",
            "name": "Oldtown Schedule",
            "url": "https://expired.badssl.com/",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def connection_aborted_config(self) -> dict:
        return {
            "extracted_at": "2026-01-06T02:00:00+00:00",
            "name": "North County Schedule",
            "url": "https://lfportal.nctd.org/staticGTFS/google_transit.zip",
            "feed_type": "schedule",
            "schedule_url_for_validation": None,
            "auth_query_params": {},
            "auth_headers": {},
            "computed": False,
        }

    @pytest.fixture
    def unauthenticated_hook(
        self, unauthenticated_download_config: dict
    ) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=unauthenticated_download_config, method="GET"
        )

    @pytest.fixture
    def header_authenticated_hook(
        self, header_authenticated_download_config: dict
    ) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=header_authenticated_download_config, method="GET"
        )

    @pytest.fixture
    def query_authenticated_hook(
        self, query_authenticated_download_config: dict
    ) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=query_authenticated_download_config, method="GET"
        )

    @pytest.fixture
    def not_found_hook(self, not_found_download_config: dict) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=not_found_download_config, method="GET"
        )

    @pytest.fixture
    def certificate_error_hook(
        self, certificate_error_download_config: dict
    ) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=certificate_error_download_config, method="GET"
        )

    @pytest.fixture
    def connection_aborted_hook(
        self, connection_aborted_config: dict
    ) -> DownloadConfigHook:
        return DownloadConfigHook(
            download_config=connection_aborted_config, method="GET"
        )

    @pytest.mark.vcr()
    def test_run_unauthenticated(self, unauthenticated_hook: DownloadConfigHook):
        result = unauthenticated_hook.run()
        assert result.headers["Content-Type"] == "application/zip"
        assert result.headers["Content-Disposition"] == "attachment; filename=gtfs.zip"
        assert len(result.content) > 0

    @pytest.mark.vcr()
    def test_run_header_authenticated(
        self, header_authenticated_hook: DownloadConfigHook
    ):
        result = header_authenticated_hook.run()
        assert result.headers["Content-Type"] == "application/x-zip-compressed"
        assert (
            result.headers["Content-Disposition"]
            == 'filename="Glendale Beeline GTFS 2025-08-18a.zip"'
        )
        assert len(result.content) > 0

    @pytest.mark.vcr()
    def test_run_query_authenticated(
        self, query_authenticated_hook: DownloadConfigHook
    ):
        result = query_authenticated_hook.run()
        assert result.headers["Content-Type"] == "application/zip"
        assert (
            result.headers["Content-Disposition"]
            == "attachment; filename=GTFSTransitData_TF.zip"
        )
        assert len(result.content) > 0

    @pytest.mark.vcr()
    def test_run_not_found(self, not_found_hook: DownloadConfigHook):
        with pytest.raises(AirflowException) as exception:
            not_found_hook.run()
        assert "NOT FOUND" in str(exception.value)

    def test_run_certificate_error(self, certificate_error_hook: DownloadConfigHook):
        with pytest.raises(SSLError) as exception:
            certificate_error_hook.run()
        assert "certificate has expired" in str(exception.value)

    def test_run_connection_aborted(self, connection_aborted_hook: DownloadConfigHook):
        result = connection_aborted_hook.run()
        assert result.headers["Content-Type"] == "application/x-zip-compressed"
        assert len(result.content) > 0
