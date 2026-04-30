r"""
Tests for metabase_dashboard_templates.

Two flows are exercised:

  - dashboard-to-template:  jinjaify + emit_template_yaml
  - template-to-dashboard:  Jinja env helpers + render_template_text + apply_dashboard

Run (from repo root):
    python -m pytest \
        tools/metabase_dashboard_templates/test_dashboard_templates.py -v
"""

import copy
import json
from unittest.mock import MagicMock

import pytest
from click.testing import CliRunner

from tools.metabase_dashboard_templates.cli import (
    STRIP_CARD_KEYS,
    apply_dashboard,
    build_card_payload,
    build_dashcard_for_put,
    cli,
    emit_template_yaml,
    is_virtual_dashcard,
    jinjaify,
    make_jinja_env,
    render_template_text,
    strip,
    strip_dashboard_for_template,
)

# --------------------------------------------------------------------------- #
# Fixtures
#
# Source DB metadata mimics what dashboard-to-template would fetch when
# walking a dashboard authored against DB 2:
#   table 14 = mart_gtfs.dim_stops      (feed_key=429, stop_id=430)
#   table 46 = mart_gtfs.dim_agency     (feed_key=74,  agency_name=76)
#
# Target DB metadata (DB 3) carries the same schema with different ids:
#   table 325 = mart_gtfs.dim_stops     (feed_key=8256, stop_id=8257)
#   table 366 = mart_gtfs.dim_agency    (feed_key=7799, agency_name=7801)
# --------------------------------------------------------------------------- #

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


# --------------------------------------------------------------------------- #
# strip()
# --------------------------------------------------------------------------- #


class TestStrip:
    def test_removes_listed_keys(self):
        assert strip({"a": 1, "b": 2, "c": 3}, {"b"}) == {"a": 1, "c": 3}

    def test_empty_keyset_is_passthrough(self):
        assert strip({"a": 1}, set()) == {"a": 1}

    def test_does_not_mutate_input(self):
        d = {"a": 1, "b": 2}
        strip(d, {"a"})
        assert d == {"a": 1, "b": 2}


# --------------------------------------------------------------------------- #
# is_virtual_dashcard()
# --------------------------------------------------------------------------- #


class TestIsVirtualDashcard:
    def test_text_dashcard_is_virtual(self):
        dc = {
            "card_id": None,
            "visualization_settings": {
                "virtual_card": {"display": "text"},
                "text": "Hi",
            },
        }
        assert is_virtual_dashcard(dc) is True

    def test_heading_dashcard_is_virtual(self):
        dc = {
            "card_id": None,
            "visualization_settings": {"virtual_card": {"display": "heading"}},
        }
        assert is_virtual_dashcard(dc) is True

    def test_real_card_is_not_virtual(self):
        dc = {"card_id": 42, "visualization_settings": {}}
        assert is_virtual_dashcard(dc) is False

    def test_null_card_id_without_virtual_card_is_not_virtual(self):
        dc = {"card_id": None, "visualization_settings": {}}
        assert is_virtual_dashcard(dc) is False

    def test_missing_visualization_settings_is_safe(self):
        assert is_virtual_dashcard({"card_id": None}) is False
        assert is_virtual_dashcard({"card_id": 42}) is False


# --------------------------------------------------------------------------- #
# strip_dashboard_for_template()
# --------------------------------------------------------------------------- #


class TestStripDashboardForTemplate:
    def test_strips_top_level_server_keys(self):
        dash = {"id": 1, "name": "X", "entity_id": "abc", "dashcards": []}
        out = strip_dashboard_for_template(dash)
        assert out == {"name": "X", "dashcards": []}

    def test_strips_per_dashcard_and_per_card_keys(self):
        dash = {
            "name": "X",
            "dashcards": [
                {
                    "id": 99,
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card_id": 5,
                    "entity_id": "dc-eid",
                    "card": {
                        "id": 5,
                        "name": "C",
                        "display": "bar",
                        "entity_id": "card-eid",
                        "view_count": 100,
                        "result_metadata": [{"id": 76}],
                        "dataset_query": {"database": 2},
                        "visualization_settings": {},
                    },
                }
            ],
        }
        out = strip_dashboard_for_template(dash)
        dc = out["dashcards"][0]
        assert "id" not in dc and "entity_id" not in dc and "card_id" not in dc
        card = dc["card"]
        assert "id" not in card and "entity_id" not in card
        assert "view_count" not in card and "result_metadata" not in card
        # Things that should still be there:
        assert card["name"] == "C"
        assert card["dataset_query"] == {"database": 2}

    def test_drops_card_block_if_only_strippable_keys(self):
        # A virtual dashcard's `card` block is full of strippable keys
        # (download_perms, query_average_duration). Should disappear.
        dash = {
            "name": "X",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "visualization_settings": {"virtual_card": {"display": "text"}},
                    "card": {"download_perms": "none", "query_average_duration": None},
                }
            ],
        }
        out = strip_dashboard_for_template(dash)
        assert "card" not in out["dashcards"][0]


# --------------------------------------------------------------------------- #
# build_dashcard_for_put()
# --------------------------------------------------------------------------- #


class TestBuildDashcardForPut:
    def test_real_card_includes_card_id(self):
        src = {
            "row": 4,
            "col": 0,
            "size_x": 12,
            "size_y": 6,
            "parameter_mappings": [],
            "visualization_settings": {},
        }
        out = build_dashcard_for_put(src, neg_id=-1, new_card_id=999)
        assert out["id"] == -1
        assert out["card_id"] == 999
        assert out["row"] == 4 and out["col"] == 0
        assert out["size_x"] == 12 and out["size_y"] == 6

    def test_virtual_card_omits_card_id(self):
        src = {
            "row": 0,
            "col": 0,
            "size_x": 24,
            "size_y": 1,
            "visualization_settings": {
                "virtual_card": {"display": "heading"},
                "text": "Title",
            },
        }
        out = build_dashcard_for_put(src, neg_id=-2, new_card_id=None)
        assert "card_id" not in out
        assert out["id"] == -2
        assert out["visualization_settings"]["virtual_card"]["display"] == "heading"

    def test_defaults_for_missing_optional_fields(self):
        src = {"row": 1, "col": 1, "size_x": 1, "size_y": 1}
        out = build_dashcard_for_put(src, neg_id=-1, new_card_id=42)
        assert out["parameter_mappings"] == []
        assert out["visualization_settings"] == {}
        assert out["series"] == []

    def test_explicit_null_optional_fields_default_to_empty(self):
        src = {
            "row": 0,
            "col": 0,
            "size_x": 1,
            "size_y": 1,
            "parameter_mappings": None,
            "visualization_settings": None,
            "series": None,
        }
        out = build_dashcard_for_put(src, neg_id=-1, new_card_id=1)
        assert out["parameter_mappings"] == []
        assert out["visualization_settings"] == {}
        assert out["series"] == []

    def test_parameter_mappings_card_id_rewritten_to_new_card_id(self):
        # parameter_mappings[].card_id from the source dashboard is meaningless
        # against the new dashboard (cards have fresh ids); rewrite to point at
        # this dashcard's own freshly-created card.  Regression for the
        # "filters not connected" symptom in #4825.
        src = {
            "row": 0,
            "col": 0,
            "size_x": 1,
            "size_y": 1,
            "parameter_mappings": [
                {
                    "parameter_id": "abc",
                    "card_id": 604,
                    "target": ["dimension", ["field", 8256]],
                },
                {
                    "parameter_id": "def",
                    "card_id": 604,
                    "target": ["dimension", ["field", 8257]],
                },
            ],
        }
        out = build_dashcard_for_put(src, neg_id=-1, new_card_id=42)
        for pm in out["parameter_mappings"]:
            assert pm["card_id"] == 42
        # Source dict not mutated.
        assert src["parameter_mappings"][0]["card_id"] == 604
        # Other fields preserved.
        assert out["parameter_mappings"][0]["parameter_id"] == "abc"
        assert out["parameter_mappings"][0]["target"] == [
            "dimension",
            ["field", 8256],
        ]

    def test_parameter_mappings_untouched_when_no_new_card_id(self):
        # Virtual dashcards have new_card_id=None.  They shouldn't carry
        # parameter_mappings in practice, but if they do we don't want to
        # clobber card_id with None.
        src = {
            "row": 0,
            "col": 0,
            "size_x": 1,
            "size_y": 1,
            "parameter_mappings": [{"parameter_id": "abc", "card_id": 999}],
        }
        out = build_dashcard_for_put(src, neg_id=-1, new_card_id=None)
        assert out["parameter_mappings"][0]["card_id"] == 999


# --------------------------------------------------------------------------- #
# build_card_payload()
# --------------------------------------------------------------------------- #


class TestBuildCardPayload:
    def _card(self):
        return {
            "name": "Test card",
            "display": "bar",
            "database_id": 3,
            "table_id": 325,
            "collection_id": 22,
            "visualization_settings": {"graph.dimensions": ["x"]},
            "dataset_query": {"database": 3, "stages": [{"source-table": 325}]},
            # Server-generated; should be stripped:
            "id": 999,
            "entity_id": "X",
            "view_count": 1,
            "result_metadata": [{"id": 76}],
            "card_schema": 23,
        }

    def test_strips_server_generated_keys(self):
        out = build_card_payload(self._card())
        for k in {"id", "entity_id", "view_count", "result_metadata", "card_schema"}:
            assert k not in out

    def test_required_fields_survive(self):
        out = build_card_payload(self._card())
        for k in ("name", "dataset_query", "display", "visualization_settings"):
            assert k in out

    def test_strips_every_key_in_strip_set(self):
        card = self._card()
        for k in STRIP_CARD_KEYS:
            card.setdefault(k, "sentinel")
        out = build_card_payload(card)
        assert STRIP_CARD_KEYS.isdisjoint(out.keys())

    def test_defaults_fill_missing_optionals(self):
        card = {"name": "C", "display": "table", "dataset_query": {"database": 3}}
        out = build_card_payload(card)
        assert out["visualization_settings"] == {}
        assert out["parameters"] == []
        assert out["parameter_mappings"] == []


# --------------------------------------------------------------------------- #
# jinjaify() -- DASHBOARD -> TEMPLATE direction
# --------------------------------------------------------------------------- #


class TestJinjaify:
    def _walk_for_jinja_text(self, dashboard, lookup) -> str:
        """Convenience: jinjaify + emit -> final template text."""
        d, ph = jinjaify(dashboard, lookup)
        return emit_template_yaml(d, ph)

    def test_database_attribute_replaced_with_jinja_expr(self, src_lookup):
        d = {
            "name": "D",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "name": "C",
                        "display": "bar",
                        "database_id": 2,
                        "table_id": 14,
                        "dataset_query": {
                            "database": 2,
                            "stages": [{"source-table": 14}],
                        },
                    },
                }
            ],
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "database_id: {{ database_id }}" in text
        assert "database: {{ database_id }}" in text
        assert 'get_table_id(database_id, "mart_gtfs.dim_stops")' in text

    def test_field_ref_legacy_form(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {
                                    "breakout": [
                                        ["field", 76, {"base-type": "type/Text"}]
                                    ]
                                }
                            ],
                        },
                    },
                }
            ]
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert (
            'get_field_id(database_id, "mart_gtfs.dim_agency", "agency_name")' in text
        )

    def test_field_ref_lib_form(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {
                                    "breakout": [
                                        ["field", {"base-type": "type/Text"}, 76]
                                    ]
                                }
                            ],
                        },
                    },
                }
            ]
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert (
            'get_field_id(database_id, "mart_gtfs.dim_agency", "agency_name")' in text
        )

    def test_native_query_only_replaces_database(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {
                                    "lib/type": "mbql.stage/native",
                                    "native": "select * from mart_gtfs.dim_stops",
                                }
                            ],
                        },
                    },
                }
            ]
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "database: {{ database_id }}" in text
        # Native SQL text is untouched.
        assert "select * from mart_gtfs.dim_stops" in text
        # No field/table helper calls were emitted.
        assert "get_table_id" not in text
        assert "get_field_id" not in text

    def test_recurses_into_joins(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {
                                    "source-table": 14,
                                    "joins": [
                                        {
                                            "stages": [{"source-table": 46}],
                                            "conditions": [
                                                [
                                                    "=",
                                                    ["field", {}, 429],
                                                    ["field", {"join-alias": "A"}, 74],
                                                ]
                                            ],
                                        }
                                    ],
                                }
                            ],
                        },
                    },
                }
            ]
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert 'get_table_id(database_id, "mart_gtfs.dim_stops")' in text
        assert 'get_table_id(database_id, "mart_gtfs.dim_agency")' in text
        assert 'get_field_id(database_id, "mart_gtfs.dim_stops", "feed_key")' in text
        assert 'get_field_id(database_id, "mart_gtfs.dim_agency", "feed_key")' in text

    def test_unrelated_int_not_remapped(self, src_lookup):
        # `limit: 14` happens to collide with table 14's id. Must not be touched.
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [{"source-table": 14, "limit": 14, "offset": 0}],
                        },
                    },
                }
            ]
        }
        d_copy, ph = jinjaify(copy.deepcopy(d), src_lookup)
        # source-table got rewritten, limit stayed numeric.
        stage = d_copy["dashcards"][0]["card"]["dataset_query"]["stages"][0]
        assert stage["source-table"].startswith("__JINJAEXPR_")
        assert stage["limit"] == 14

    def test_unknown_table_id_raises(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "table_id": 99999,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ]
        }
        with pytest.raises(Exception, match="99999"):
            jinjaify(d, src_lookup)

    def test_unknown_field_id_raises(self, src_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [{"breakout": [["field", {}, 99999]]}],
                        },
                    },
                }
            ]
        }
        with pytest.raises(Exception, match="99999"):
            jinjaify(d, src_lookup)

    def test_multiple_source_databases_raises(self, src_meta):
        # Two cards on different DBs -- prototype declines to template.
        meta_2 = src_meta
        meta_4 = copy.deepcopy(SRC_META)  # DB 4: same schema, shifted ids
        for k in ("table_by_id", "field_by_id"):
            for old, val in list(meta_4[k].items()):
                del meta_4[k][old]
                meta_4[k][old + 1000] = val

        def lookup(db_id):
            if db_id == 2:
                return meta_2
            if db_id == 4:
                return meta_4
            raise KeyError(db_id)

        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                },
                {
                    "row": 1,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 4,
                        "dataset_query": {"database": 4, "stages": []},
                    },
                },
            ]
        }
        with pytest.raises(Exception, match="multiple source databases"):
            jinjaify(d, lookup)

    def test_field_refs_in_parameter_mappings_target_are_substituted(
        self, src_lookup
    ):
        # parameter_mappings is a sibling of `card` at the dashcard level, so
        # without inheriting db_id from card.dataset_query.database, field-refs
        # inside parameter_mappings.target would be left as raw ints.  Regression
        # test for the broken-filter symptom seen in #4825.
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "parameter_mappings": [
                        {
                            "parameter_id": "abc123",
                            "card_id": 999,
                            "target": ["dimension", ["field", 76, {}]],
                        }
                    ],
                    "card": {
                        "name": "C",
                        "display": "bar",
                        "database_id": 2,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ]
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert (
            'get_field_id(database_id, "mart_gtfs.dim_agency", "agency_name")' in text
        )

    def test_collection_id_replaced_at_card_and_dashboard_level(self, src_lookup):
        d = {
            "name": "D",
            "collection_id": 145,
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "name": "C",
                        "display": "bar",
                        "database_id": 2,
                        "collection_id": 145,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ],
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        # Both the dashboard-level and card-level collection_id should be templated.
        assert text.count("collection_id: {{ collection_id }}") == 2

    def test_dashcard_viz_settings_with_stale_field_id_does_not_raise(
        self, src_lookup
    ):
        # Dashcard-level visualization_settings can carry stale field ids
        # (column dropped or DB connection rebuilt).  Metabase tolerates
        # these at runtime; the export should warn-and-leave instead of
        # hard-failing.  Regression for staging dashboard 11 (#4825).
        d = {
            "name": "D",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    # Dashcard-level viz settings -- viz_table can't be
                    # inferred from the dashcard itself, so the lenient
                    # path has to kick in via inside_viz tracking.
                    "visualization_settings": {
                        "table.columns": [
                            {
                                "name": "Some Column",
                                "fieldRef": ["field", 99999, {}],
                            }
                        ]
                    },
                    "card": {
                        "name": "C",
                        "display": "table",
                        "database_id": 2,
                        "dataset_query": {
                            "database": 2,
                            "stages": [{"source-table": 14}],
                        },
                    },
                }
            ],
        }
        cleaned, ph = jinjaify(copy.deepcopy(d), src_lookup)
        text = emit_template_yaml(cleaned, ph)
        # Stale id passes through to the rendered template as a raw int
        # (Metabase will name-match at runtime, same as in the source).
        assert "99999" in text

    def test_dashboard_name_auto_templatized_by_default(self, src_lookup):
        d = {
            "name": "MST Payments",
            "dashcards": [],
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "name: {{ dashboard_name }}" in text
        assert "MST Payments" not in text

    def test_no_templatize_name_preserves_literal(self, src_lookup):
        d = {"name": "MST Payments", "dashcards": []}
        cleaned, ph = jinjaify(
            copy.deepcopy(d), src_lookup, templatize_name=False
        )
        text = emit_template_yaml(cleaned, ph)
        assert "name: MST Payments" in text
        assert "{{ dashboard_name }}" not in text

    def test_dashboard_without_name_does_not_emit_dashboard_name_var(
        self, src_lookup
    ):
        # Templatize-name is opportunistic: no top-level name -> no var.
        d = {"dashcards": []}
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "{{ dashboard_name }}" not in text

    def test_card_level_name_not_touched_by_templatize_name(self, src_lookup):
        # Only the dashboard's top-level name is templatized; cards keep theirs.
        d = {
            "name": "Top",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "name": "Card name stays literal",
                        "display": "bar",
                        "database_id": 2,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ],
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "name: Card name stays literal" in text

    def test_substitution_replaces_literal_in_string_values(self, src_lookup):
        d = {
            "name": "Top",
            "description": "MST overview",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "visualization_settings": {
                        "virtual_card": {"display": "heading"},
                        "text": "MST Payments",
                    },
                },
            ],
        }
        cleaned, ph = jinjaify(
            copy.deepcopy(d),
            src_lookup,
            substitutions=[("MST", "agency_short")],
        )
        text = emit_template_yaml(cleaned, ph)
        assert "description: {{ agency_short }} overview" in text
        assert "text: {{ agency_short }} Payments" in text
        assert "MST" not in text

    def test_substitution_does_not_match_in_dict_keys(self, src_lookup):
        # If a dashboard's metadata happens to use the literal as a key
        # (e.g. visualization_settings entries keyed by user labels), the
        # key should NOT be substituted -- only string values.
        d = {
            "name": "Top",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "visualization_settings": {
                        "MST_label_column": {"text": "MST data"},
                    },
                }
            ],
        }
        cleaned, ph = jinjaify(
            copy.deepcopy(d),
            src_lookup,
            substitutions=[("MST", "agency_short")],
        )
        text = emit_template_yaml(cleaned, ph)
        # Key untouched.
        assert "MST_label_column" in text
        # Value substituted.
        assert "{{ agency_short }} data" in text

    def test_substitution_longer_literal_takes_priority(self, src_lookup):
        # When two literals overlap (one is a prefix or substring of the
        # other), the longer one should bind to its match before the
        # shorter one consumes it.
        d = {
            "name": "Top",
            "description": "Mendocino Transit Authority - Mendocino zone",
            "dashcards": [],
        }
        cleaned, ph = jinjaify(
            copy.deepcopy(d),
            src_lookup,
            substitutions=[
                ("Mendocino", "agency_short"),
                ("Mendocino Transit Authority", "agency_long"),
            ],
        )
        text = emit_template_yaml(cleaned, ph)
        # Long-form match wins where both could apply; remainder uses short.
        assert "{{ agency_long }} - {{ agency_short }} zone" in text

    def test_substitution_renders_through_full_pipeline(
        self, src_lookup, tgt_lookup
    ):
        # End-to-end: export with substitutions, render with context, the
        # rendered values land in the right places.
        d = {
            "name": "Top",
            "description": "MST overview",
            "dashcards": [],
        }
        cleaned, ph = jinjaify(
            copy.deepcopy(d),
            src_lookup,
            substitutions=[("MST", "agency_short")],
        )
        text = emit_template_yaml(cleaned, ph)
        env = make_jinja_env(tgt_lookup)
        rendered = render_template_text(
            text,
            {
                "database_id": 3,
                "dashboard_name": "Foothill Payments",
                "agency_short": "Foothill",
            },
            env,
        )
        assert rendered["name"] == "Foothill Payments"
        assert rendered["description"] == "Foothill overview"

    def test_multiple_source_collections_raises(self, src_lookup):
        d = {
            "collection_id": 145,
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "collection_id": 999,  # different collection
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ],
        }
        with pytest.raises(Exception, match="multiple source collections"):
            jinjaify(d, src_lookup)


# --------------------------------------------------------------------------- #
# emit_template_yaml() -- placeholder substitution + Jinja round-trip
# --------------------------------------------------------------------------- #


class TestEmitTemplateYaml:
    def test_jinja_expression_stays_unquoted_so_int_survives_round_trip(
        self,
        src_lookup,
    ):
        # The whole point: a Jinja expression standing in for an int must
        # NOT be wrapped in quotes by yaml.safe_dump, so that after Jinja
        # rendering the resulting YAML parses the substituted value as int.
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ]
        }
        text = emit_template_yaml(*jinjaify(d, src_lookup))
        # The substitution itself shouldn't be quoted.
        assert "database: {{ database_id }}" in text
        assert "database: '{{ database_id }}'" not in text
        assert 'database: "{{ database_id }}"' not in text

        # And after Jinja rendering with a real int, YAML parses it as int.
        env = make_jinja_env(lambda _: TGT_META)
        parsed = render_template_text(text, {"database_id": 7}, env)
        ds_query_db = parsed["dashcards"][0]["card"]["dataset_query"]["database"]
        assert ds_query_db == 7
        assert isinstance(ds_query_db, int)

    def test_placeholder_strings_are_fully_replaced(self, src_lookup):
        # No __JINJAEXPR_*__ tokens should leak through to the final YAML.
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "table_id": 14,
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {"source-table": 14, "breakout": [["field", {}, 76]]}
                            ],
                        },
                    },
                }
            ]
        }
        text = emit_template_yaml(*jinjaify(d, src_lookup))
        assert "__JINJAEXPR_" not in text


# --------------------------------------------------------------------------- #
# make_jinja_env(): Jinja-exposed helpers
# --------------------------------------------------------------------------- #


class TestJinjaHelpers:
    def test_get_table_id_with_qualified_name(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string('{{ get_table_id(database_id, "mart_gtfs.dim_stops") }}')
        assert tpl.render(database_id=3) == "325"

    def test_get_table_id_with_unqualified_unique_name(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string('{{ get_table_id(database_id, "dim_stops") }}')
        assert tpl.render(database_id=3) == "325"

    def test_get_table_id_unknown_table_raises(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string(
            '{{ get_table_id(database_id, "mart_gtfs.does_not_exist") }}'
        )
        with pytest.raises(Exception, match="not found in target DB"):
            tpl.render(database_id=3)

    def test_get_table_id_ambiguous_unqualified_name_raises(self):
        # Same table name in two different schemas must error if unqualified.
        meta = {
            "table_to_id": {("a", "users"): 1, ("b", "users"): 2},
            "table_by_id": {1: ("a", "users"), 2: ("b", "users")},
            "field_to_id": {},
            "field_by_id": {},
        }
        env = make_jinja_env(lambda _: meta)
        tpl = env.from_string('{{ get_table_id(database_id, "users") }}')
        with pytest.raises(Exception, match="ambiguous"):
            tpl.render(database_id=99)

    def test_get_field_id_qualified(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        out = env.from_string(
            '{{ get_field_id(database_id, "mart_gtfs.dim_stops", "feed_key") }}'
        ).render(database_id=3)
        assert out == "8256"

    def test_get_field_id_unknown_field_raises(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        with pytest.raises(Exception, match="not found in target DB"):
            env.from_string(
                '{{ get_field_id(database_id, "mart_gtfs.dim_stops", "nope") }}'
            ).render(database_id=3)

    def test_metadata_lookup_is_cached_per_db_id(self, tgt_meta):
        calls = []

        def lookup(db_id):
            calls.append(db_id)
            return tgt_meta

        env = make_jinja_env(lookup)
        tpl1 = env.from_string('{{ get_table_id(database_id, "dim_stops") }}')
        tpl2 = env.from_string(
            '{{ get_field_id(database_id, "dim_stops", "feed_key") }}'
        )
        tpl1.render(database_id=3)
        tpl2.render(database_id=3)
        # One fetch only, even across multiple calls.
        assert calls == [3]


# --------------------------------------------------------------------------- #
# render_template_text() -- full Jinja+YAML pipeline
# --------------------------------------------------------------------------- #


class TestRenderTemplateText:
    def test_full_round_trip_export_then_render(self, src_lookup, tgt_lookup):
        """
        Author a dashboard against DB 2, jinjaify it into a template,
        then render that template against DB 3 -- ids should land in DB 3's space.
        """
        source = {
            "name": "Roundtrip",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 12,
                    "size_y": 6,
                    "card": {
                        "name": "Q",
                        "display": "bar",
                        "database_id": 2,
                        "table_id": 14,
                        "visualization_settings": {},
                        "dataset_query": {
                            "database": 2,
                            "stages": [
                                {
                                    "source-table": 14,
                                    "breakout": [
                                        ["field", {"base-type": "type/Text"}, 76]
                                    ],
                                }
                            ],
                        },
                    },
                }
            ],
        }
        # Export
        d, ph = jinjaify(copy.deepcopy(source), src_lookup)
        text = emit_template_yaml(d, ph)
        # Apply against DB 3
        env = make_jinja_env(tgt_lookup)
        rendered = render_template_text(
            text,
            {"database_id": 3, "dashboard_name": "Roundtrip - Foothill"},
            env,
        )
        assert rendered["name"] == "Roundtrip - Foothill"
        card = rendered["dashcards"][0]["card"]
        assert card["database_id"] == 3
        assert card["table_id"] == 325
        ds = card["dataset_query"]
        assert ds["database"] == 3
        assert ds["stages"][0]["source-table"] == 325
        # Field-ref id remapped to DB 3's space.
        assert ds["stages"][0]["breakout"][0][2] == 7801

    def test_strict_undefined_raises_on_missing_context(self, src_lookup, tgt_lookup):
        d = {
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "database_id": 2,
                        "dataset_query": {"database": 2, "stages": []},
                    },
                }
            ]
        }
        text = emit_template_yaml(*jinjaify(d, src_lookup))
        env = make_jinja_env(tgt_lookup)
        # Missing database_id -> StrictUndefined raises.
        with pytest.raises(Exception, match="database_id"):
            render_template_text(text, {}, env)


# --------------------------------------------------------------------------- #
# apply_dashboard() -- end-to-end with a mocked HTTP session
# --------------------------------------------------------------------------- #


def _make_fake_session(card_ids=(501, 502, 503), dashboard_id=999):
    """Build a MagicMock session that simulates POSTs for cards/dashboard."""
    calls = {"posts": [], "puts": []}
    iter_cards = iter(card_ids)

    def fake_post(url, json=None, **kw):
        calls["posts"].append((url, json))
        resp = MagicMock()
        if url.endswith("/api/card"):
            resp.json.return_value = {"id": next(iter_cards), "name": json["name"]}
        elif url.endswith("/api/dashboard/"):
            resp.json.return_value = {"id": dashboard_id, "name": json["name"]}
        return resp

    def fake_put(url, json=None, **kw):
        calls["puts"].append((url, json))
        resp = MagicMock()
        resp.json.return_value = {"id": dashboard_id}
        return resp

    sess = MagicMock()
    sess.post.side_effect = fake_post
    sess.put.side_effect = fake_put
    return sess, calls


class TestApplyDashboardCreate:
    def test_creates_cards_then_dashboard_then_attaches_dashcards(self):
        spec = {
            "name": "Created",
            "description": "d",
            "collection_id": 22,
            "dashcards": [
                {  # Real chart card.
                    "row": 4,
                    "col": 0,
                    "size_x": 12,
                    "size_y": 6,
                    "parameter_mappings": [],
                    "visualization_settings": {},
                    "card": {
                        "name": "Q",
                        "display": "bar",
                        "database_id": 3,
                        "table_id": 325,
                        "collection_id": 22,
                        "visualization_settings": {},
                        "dataset_query": {
                            "database": 3,
                            "stages": [{"source-table": 325}],
                        },
                    },
                },
                {  # Heading.
                    "row": 0,
                    "col": 0,
                    "size_x": 24,
                    "size_y": 1,
                    "visualization_settings": {
                        "virtual_card": {"display": "heading"},
                        "text": "Title",
                    },
                },
            ],
        }
        sess, calls = _make_fake_session()
        apply_dashboard(sess, "https://m.example", spec, existing_dashboard_id=None)

        # 1 card POST (virtual heading skipped).
        card_posts = [c for c in calls["posts"] if c[0].endswith("/api/card")]
        assert len(card_posts) == 1
        # Dashboard POST contains only the POST-allowed subset.
        dash_posts = [c for c in calls["posts"] if c[0].endswith("/api/dashboard/")]
        assert len(dash_posts) == 1
        post_body = dash_posts[0][1]
        assert post_body["name"] == "Created"
        assert post_body["description"] == "d"
        assert post_body["collection_id"] == 22
        assert "dashcards" not in post_body  # PUT carries dashcards, not POST

        # PUT carries the full template + a 2-element dashcards array.
        assert len(calls["puts"]) == 1
        put_url, put_body = calls["puts"][0]
        assert put_url.endswith("/api/dashboard/999")
        dcs = put_body["dashcards"]
        assert len(dcs) == 2
        real = [d for d in dcs if "card_id" in d][0]
        assert real["card_id"] == 501
        assert real["id"] < 0
        virtual = [d for d in dcs if "card_id" not in d][0]
        assert virtual["visualization_settings"]["virtual_card"]["display"] == "heading"

    def test_parameter_mappings_card_id_rewritten_through_apply(self):
        # End-to-end: source-side parameter_mappings.card_id flows through
        # apply_dashboard and lands as the freshly-minted card's id in the
        # PUT body.
        spec = {
            "name": "Created",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 12,
                    "size_y": 6,
                    "parameter_mappings": [
                        {
                            "parameter_id": "p1",
                            "card_id": 604,
                            "target": ["dimension", ["field", 8256]],
                        },
                    ],
                    "visualization_settings": {},
                    "card": {
                        "name": "Q",
                        "display": "bar",
                        "database_id": 3,
                        "visualization_settings": {},
                        "dataset_query": {"database": 3, "stages": []},
                    },
                },
            ],
        }
        sess, calls = _make_fake_session(card_ids=(501,))
        apply_dashboard(sess, "https://m.example", spec, existing_dashboard_id=None)
        _, put_body = calls["puts"][0]
        dc = put_body["dashcards"][0]
        assert dc["card_id"] == 501
        assert dc["parameter_mappings"][0]["card_id"] == 501

    def test_missing_top_level_name_raises(self):
        spec = {"description": "no name", "dashcards": []}
        sess, _ = _make_fake_session()
        with pytest.raises(Exception, match="name"):
            apply_dashboard(sess, "https://m.example", spec, existing_dashboard_id=None)

    def test_non_virtual_dashcard_without_card_block_raises(self):
        spec = {
            "name": "X",
            "dashcards": [{"row": 0, "col": 0, "size_x": 1, "size_y": 1}],
        }
        sess, _ = _make_fake_session()
        with pytest.raises(Exception, match="card"):
            apply_dashboard(sess, "https://m.example", spec, existing_dashboard_id=None)


class TestApplyDashboardUpdate:
    def test_update_skips_dashboard_post_and_puts_to_existing_id(self):
        spec = {
            "name": "Updated",
            "description": "new desc",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "name": "Q2",
                        "display": "table",
                        "database_id": 3,
                        "visualization_settings": {},
                        "dataset_query": {"database": 3, "stages": []},
                    },
                }
            ],
        }
        sess, calls = _make_fake_session()
        apply_dashboard(sess, "https://m.example", spec, existing_dashboard_id=42)

        # POST should be the new card only -- no /api/dashboard/ POST in update mode.
        post_urls = [u for u, _ in calls["posts"]]
        assert any(u.endswith("/api/card") for u in post_urls)
        assert not any(u.endswith("/api/dashboard/") for u in post_urls)

        # PUT goes to the existing dashboard id.
        assert len(calls["puts"]) == 1
        put_url, put_body = calls["puts"][0]
        assert put_url.endswith("/api/dashboard/42")
        # Top-level fields from the template are forwarded.
        assert put_body["name"] == "Updated"
        assert put_body["description"] == "new desc"
        # dashcards is full-replace.
        assert len(put_body["dashcards"]) == 1


# --------------------------------------------------------------------------- #
# CLI smoke tests (Click)
# --------------------------------------------------------------------------- #


class TestCliSmoke:
    def test_help_lists_both_subcommands(self):
        runner = CliRunner()
        # Top-level --help requires the parent options to NOT be enforced before --help.
        # Click handles this fine; we still pass dummies to satisfy required=True.
        result = runner.invoke(
            cli,
            [
                "--metabase-url",
                "https://m.example",
                "--metabase-api-key",
                "x",
                "--help",
            ],
        )
        assert result.exit_code == 0
        assert "dashboard-to-template" in result.output
        assert "template-to-dashboard" in result.output

    def test_template_to_dashboard_dry_run_renders_without_writes(
        self,
        monkeypatch,
        tmp_path,
        src_lookup,
        tgt_lookup,
    ):
        import tools.metabase_dashboard_templates.cli as mod

        # Build a tiny template via the export path and write it to disk.
        d = {
            "name": "Tpl",
            "dashcards": [
                {
                    "row": 0,
                    "col": 0,
                    "size_x": 1,
                    "size_y": 1,
                    "card": {
                        "name": "C",
                        "display": "bar",
                        "database_id": 2,
                        "table_id": 14,
                        "visualization_settings": {},
                        "dataset_query": {
                            "database": 2,
                            "stages": [{"source-table": 14}],
                        },
                    },
                }
            ],
        }
        text = emit_template_yaml(*jinjaify(copy.deepcopy(d), src_lookup))
        tpl = tmp_path / "tpl.yml"
        tpl.write_text(text)

        # Stub HTTP-bound helpers so the CLI never reaches the network.
        monkeypatch.setattr(mod, "make_session", lambda key: MagicMock())
        monkeypatch.setattr(
            mod,
            "fetch_database_metadata",
            lambda sess, base_url, db_id: tgt_lookup(db_id),
        )

        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "--metabase-url",
                "https://m.example",
                "--metabase-api-key",
                "x",
                "template-to-dashboard",
                "--template-file",
                str(tpl),
                "--template-context",
                '{"database_id": 3, "dashboard_name": "Tpl-test"}',
                "--dry-run",
            ],
        )
        assert result.exit_code == 0, result.output
        # Dry-run output is the rendered spec as JSON.  Verify the rendered
        # ids landed in DB-3's id space (table 325, database 3).
        spec = json.loads(result.output)
        card = spec["dashcards"][0]["card"]
        assert card["database_id"] == 3
        assert card["table_id"] == 325

    @pytest.mark.parametrize(
        "bad,error_match",
        [
            ("MST", "LITERAL=VARNAME"),  # missing =
            ("=agency_short", "non-empty"),  # empty literal
            ("MST=123agency", "valid identifier"),  # invalid varname
            ("MST=agency-short", "valid identifier"),  # hyphen in varname
        ],
    )
    def test_dashboard_to_template_rejects_bad_substitutions(
        self,
        monkeypatch,
        tmp_path,
        bad,
        error_match,
    ):
        import tools.metabase_dashboard_templates.cli as mod

        monkeypatch.setattr(mod, "make_session", lambda key: MagicMock())
        # The substitution validation runs before the network calls, so we
        # don't even need a fake fetch_dashboard.
        runner = CliRunner()
        result = runner.invoke(
            cli,
            [
                "--metabase-url",
                "https://m.example",
                "--metabase-api-key",
                "x",
                "dashboard-to-template",
                "--dashboard-id",
                "1",
                "--template-file",
                str(tmp_path / "out.yml"),
                "--substitution",
                bad,
            ],
        )
        assert result.exit_code != 0
        assert error_match in result.output
