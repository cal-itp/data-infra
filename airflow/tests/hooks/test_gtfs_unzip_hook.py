import os
from datetime import datetime, timezone

import pytest
from hooks.gtfs_unzip_hook import GTFSUnzipHook


class TestGTFSUnzipHook:
    @pytest.fixture
    def download_schedule_feed_results(self) -> dict:
        return {
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

    @pytest.fixture
    def date(self) -> datetime:
        return datetime.fromisoformat("2025-11-15").replace(tzinfo=timezone.utc)

    @pytest.fixture
    def fixture_schedule_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)), "../fixtures/schedule.zip"
            )
        )

    @pytest.fixture
    def success_macos_directory_schedule_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/GuadalupeFlyerParatransitFlex.zip",
            )
        )

    @pytest.fixture
    def nested_macos_directory_schedule_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/HumboldtTransitAuthorityDialARideFlex.zip",
            )
        )

    @pytest.fixture
    def failing_nested_schedule_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/bad-nested-schedule.zip",
            )
        )

    @pytest.fixture
    def failing_schedule_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/bad-schedule.zip",
            )
        )

    @pytest.fixture
    def fixture_corrupted_zip_path(self) -> str:
        return os.path.normpath(
            os.path.join(
                os.path.dirname(os.path.realpath(__file__)),
                "../fixtures/corrupted_RTD_GTFS.zip",
            )
        )

    @pytest.fixture
    def hook(self, date: datetime) -> GTFSUnzipHook:
        return GTFSUnzipHook(
            filenames=["agency.txt", "calendar.txt"], current_date=date.isoformat()
        )

    def test_run(
        self,
        hook: GTFSUnzipHook,
        fixture_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = hook.run(
            zipfile_path=fixture_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
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
            "extracted_files": [
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "agency.txt",
                    "original_filename": "agency.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "calendar.txt",
                    "original_filename": "calendar.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
            ],
            "zipfile_dirs": [],
            "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
            "zipfile_files": [
                "agency.txt",
                "calendar.txt",
                "calendar_dates.txt",
                "fare_attributes.txt",
                "feed_info.txt",
                "route_directions.txt",
                "routes.txt",
                "shapes.txt",
                "stop_times.txt",
                "stops.txt",
                "transfers.txt",
                "trips.txt",
            ],
        }

    def test_success_macos_directory(
        self,
        hook: GTFSUnzipHook,
        success_macos_directory_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = hook.run(
            zipfile_path=success_macos_directory_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
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
            "extracted_files": [
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "agency.txt",
                    "original_filename": "agency.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "calendar.txt",
                    "original_filename": "calendar.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
            ],
            "zipfile_dirs": [],
            "zipfile_extract_md5hash": "1c528b720355ce5ae47bacbc2d7783b6",
            "zipfile_files": [
                "agency.txt",
                "booking_rules.txt",
                "calendar.txt",
                "feed_info.txt",
                "location_groups.txt",
                "locations.geojson",
                "routes.txt",
                "stop_times.txt",
                "trips.txt",
            ],
        }

    def test_nested_macos_directory(
        self,
        hook: GTFSUnzipHook,
        nested_macos_directory_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = hook.run(
            zipfile_path=nested_macos_directory_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
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
            "extracted_files": [
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "agency.txt",
                    "original_filename": "HumboldtTransitAuthorityDialARideFlex/agency.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
                {
                    "ts": "2025-11-15T00:00:00+00:00",
                    "filename": "calendar.txt",
                    "original_filename": "HumboldtTransitAuthorityDialARideFlex/calendar.txt",
                    "extract_config": {
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                        "name": "Santa Ynez Mecatran Schedule",
                        "url": "http://app.mecatran.com/urb/ws/feed/c2l0ZT1zeXZ0O2NsaWVudD1zZWxmO2V4cGlyZT07dHlwZT1ndGZzO2tleT00MjcwNzQ0ZTY4NTAzOTMyMDIxMDdjNzI0MDRkMzYyNTM4MzI0YzI0",
                        "feed_type": "schedule",
                        "schedule_url_for_validation": None,
                        "auth_query_params": {},
                        "auth_headers": {},
                        "computed": False,
                    },
                },
            ],
            "zipfile_dirs": ["HumboldtTransitAuthorityDialARideFlex/"],
            "zipfile_extract_md5hash": "3153abcb9b63490c5b712657e1860607",
            "zipfile_files": [
                "HumboldtTransitAuthorityDialARideFlex/agency.txt",
                "HumboldtTransitAuthorityDialARideFlex/booking_rules.txt",
                "HumboldtTransitAuthorityDialARideFlex/calendar.txt",
                "HumboldtTransitAuthorityDialARideFlex/feed_info.txt",
                "HumboldtTransitAuthorityDialARideFlex/location_groups.txt",
                "HumboldtTransitAuthorityDialARideFlex/locations.geojson",
                "HumboldtTransitAuthorityDialARideFlex/routes.txt",
                "HumboldtTransitAuthorityDialARideFlex/stop_times.txt",
                "HumboldtTransitAuthorityDialARideFlex/stops.txt",
                "HumboldtTransitAuthorityDialARideFlex/trips.txt",
            ],
        }

    def test_failing_nested_directory(
        self,
        hook: GTFSUnzipHook,
        failing_nested_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = hook.run(
            zipfile_path=failing_nested_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
        assert result.results() == {
            "success": False,
            "exception": "Unparseable zip: File/directory structure within zipfile cannot be unpacked",
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
            "extracted_files": [],
            "zipfile_dirs": ["schedule/", "schedule/nope/"],
            "zipfile_extract_md5hash": "9aabd61cc0a2db20bd6e475d4d173bbb",
            "zipfile_files": [
                "schedule/.DS_Store",
                "schedule/agency.txt",
                "schedule/nope/.DS_Store",
                "schedule/nope/README.md",
            ],
        }

    def test_failing_directory(
        self,
        hook: GTFSUnzipHook,
        failing_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = hook.run(
            zipfile_path=failing_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
        assert result.results() == {
            "success": False,
            "exception": "Unparseable zip: File/directory structure within zipfile cannot be unpacked",
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
            "extracted_files": [],
            "zipfile_dirs": [
                "nested/",
            ],
            "zipfile_extract_md5hash": "536aff47792722b597c4395e3b6bee03",
            "zipfile_files": [
                "agency.txt",
                "nested/README.md",
            ],
        }

    @pytest.fixture
    def areas_hook(self, date: datetime) -> GTFSUnzipHook:
        return GTFSUnzipHook(filenames=["areas.txt"], current_date=date.isoformat())

    def test_no_txt_file(
        self,
        areas_hook: GTFSUnzipHook,
        fixture_schedule_path: str,
        download_schedule_feed_results: dict,
    ):
        result = areas_hook.run(
            zipfile_path=fixture_schedule_path,
            download_schedule_feed_results=download_schedule_feed_results,
        )
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
            "extracted_files": [],
            "zipfile_dirs": [],
            "zipfile_extract_md5hash": "4f72c84bd3f053ddb929289fa2de7879",
            "zipfile_files": [
                "agency.txt",
                "calendar.txt",
                "calendar_dates.txt",
                "fare_attributes.txt",
                "feed_info.txt",
                "route_directions.txt",
                "routes.txt",
                "shapes.txt",
                "stop_times.txt",
                "stops.txt",
                "transfers.txt",
                "trips.txt",
            ],
        }

    def test_corrupted_zip_file(
        self,
        hook: GTFSUnzipHook,
        fixture_corrupted_zip_path: str,
    ):
        result = hook.run(
            zipfile_path=fixture_corrupted_zip_path,
            download_schedule_feed_results={
                "success": False,
                "backfilled": False,
                "config": {
                    "auth_headers": {},
                    "auth_query_params": {},
                    "computed": False,
                    "extracted_at": "2025-11-14T02:00:00+00:00",
                    "feed_type": "schedule",
                    "name": "San Joaquin Schedule",
                    "schedule_url_for_validation": None,
                    "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                },
                "exception": "File is not a zip file",
                "extract": {
                    "filename": "RTD-GTFS.zip",
                    "ts": "2025-06-03T00:00:00+00:00",
                    "config": {
                        "auth_headers": {},
                        "auth_query_params": {},
                        "computed": False,
                        "feed_type": "schedule",
                        "name": "San Joaquin Schedule",
                        "schedule_url_for_validation": None,
                        "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                        "extracted_at": "2025-06-01T00:00:00+00:00",
                    },
                    "response_code": 200,
                    "response_headers": {
                        "Content-Type": "application/zip",
                    },
                    "reconstructed": False,
                },
            },
        )
        assert result.results() == {
            "success": False,
            "exception": "File is not a zip file",
            "extract": {
                "filename": "RTD-GTFS.zip",
                "ts": "2025-06-03T00:00:00+00:00",
                "config": {
                    "extracted_at": "2025-06-01T00:00:00+00:00",
                    "name": "San Joaquin Schedule",
                    "url": "http://sanjoaquinrtd.com/RTD-GTFS/RTD-GTFS.zip",
                    "feed_type": "schedule",
                    "schedule_url_for_validation": None,
                    "auth_query_params": {},
                    "auth_headers": {},
                    "computed": False,
                },
                "response_code": 200,
                "response_headers": {
                    "Content-Type": "application/zip",
                },
                "reconstructed": False,
            },
            "extracted_files": [],
            "zipfile_dirs": [],
            "zipfile_extract_md5hash": "d41d8cd98f00b204e9800998ecf8427e",
            "zipfile_files": [],
        }
