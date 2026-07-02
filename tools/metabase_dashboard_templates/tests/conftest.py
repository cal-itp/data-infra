"""Shared fixtures for the metabase_flow test suite.

Source DB metadata mimics what dashboard-to-template would fetch when
walking a dashboard authored against DB 2:
  table 14 = mart_gtfs.dim_stops      (feed_key=429, stop_id=430)
  table 46 = mart_gtfs.dim_agency     (feed_key=74,  agency_name=76)

Target DB metadata (DB 3) carries the same schema with different ids:
  table 325 = mart_gtfs.dim_stops     (feed_key=8256, stop_id=8257)
  table 366 = mart_gtfs.dim_agency    (feed_key=7799, agency_name=7801)
"""

import copy

import pytest

SRC_META = {
    "table_by_id": {
        14: ("mart_gtfs", "dim_stops"),
        46: ("mart_gtfs", "dim_agency"),
    },
    "field_by_id": {
        429: ("mart_gtfs", "dim_stops", "feed_key"),
        430: ("mart_gtfs", "dim_stops", "stop_id"),
        74: ("mart_gtfs", "dim_agency", "feed_key"),
        76: ("mart_gtfs", "dim_agency", "agency_name"),
    },
    "table_to_id": {
        ("mart_gtfs", "dim_stops"): 14,
        ("mart_gtfs", "dim_agency"): 46,
    },
    "field_to_id": {
        ("mart_gtfs", "dim_stops", "feed_key"): 429,
        ("mart_gtfs", "dim_stops", "stop_id"): 430,
        ("mart_gtfs", "dim_agency", "feed_key"): 74,
        ("mart_gtfs", "dim_agency", "agency_name"): 76,
    },
}

TGT_META = {
    "table_by_id": {
        325: ("mart_gtfs", "dim_stops"),
        366: ("mart_gtfs", "dim_agency"),
    },
    "field_by_id": {
        8256: ("mart_gtfs", "dim_stops", "feed_key"),
        8257: ("mart_gtfs", "dim_stops", "stop_id"),
        7799: ("mart_gtfs", "dim_agency", "feed_key"),
        7801: ("mart_gtfs", "dim_agency", "agency_name"),
    },
    "table_to_id": {
        ("mart_gtfs", "dim_stops"): 325,
        ("mart_gtfs", "dim_agency"): 366,
    },
    "field_to_id": {
        ("mart_gtfs", "dim_stops", "feed_key"): 8256,
        ("mart_gtfs", "dim_stops", "stop_id"): 8257,
        ("mart_gtfs", "dim_agency", "feed_key"): 7799,
        ("mart_gtfs", "dim_agency", "agency_name"): 7801,
    },
}


@pytest.fixture
def src_meta():
    return copy.deepcopy(SRC_META)


@pytest.fixture
def tgt_meta():
    return copy.deepcopy(TGT_META)


@pytest.fixture
def src_lookup(src_meta):
    """Stub for jinjaify's fetch_metadata callable (single source DB = 2)."""

    def _lookup(db_id: int) -> dict:
        if db_id == 2:
            return src_meta
        raise KeyError(f"unexpected db_id {db_id} in test")

    return _lookup


@pytest.fixture
def tgt_lookup(tgt_meta):
    """Stub for make_jinja_env's metadata_lookup callable (target DB = 3)."""

    def _lookup(db_id: int) -> dict:
        if db_id == 3:
            return tgt_meta
        raise KeyError(f"unexpected db_id {db_id} in test")

    return _lookup
