"""Tests for metabase_flow.template_export.

Covers strip / is_virtual_dashcard / strip_dashboard_for_template and the
dashboard -> template direction (jinjaify + emit_template_yaml).  A few
round-trip tests render the emitted template via template_apply to confirm it
parses back to the expected ids.
"""

import copy
import logging

import pytest
from metabase_flow.template_apply import make_jinja_env, render_template_text
from metabase_flow.template_export import (
    emit_template_yaml,
    is_virtual_dashcard,
    jinjaify,
    strip,
    strip_dashboard_for_template,
)

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
        assert "database_id: ${ database_id }" in text
        assert "database: ${ database_id }" in text
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
        assert "database: ${ database_id }" in text
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

    def test_multiple_source_databases_is_warning_not_error(self, src_meta, caplog):
        # Real-world dashboards (e.g. CCJPA Reconciliation) occasionally
        # span multiple source DB connections -- main cards against the
        # warehouse, parameter-value cards against a metadata DB, etc.
        # Since every `database` ref in the template collapses to the same
        # `${ database_id }` placeholder, all cards land against whichever
        # single target DB the user picks at apply time.  Schema/table
        # names were discovered from each source DB's metadata; the lookup
        # at apply time uses the target's metadata.  If a referenced table
        # is missing on the target, apply will fail clearly later -- but
        # the export itself should proceed with a heads-up warning.
        meta_2 = src_meta
        meta_4 = copy.deepcopy(src_meta)  # DB 4: same schema, shifted ids
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
        with caplog.at_level(logging.WARNING):
            cleaned, _ = jinjaify(d, lookup)
        # Both card-level `database_id` slots got the placeholder.
        for dc in cleaned["dashcards"]:
            assert dc["card"]["database_id"].startswith("__JINJAEXPR_")
        # And the user got a heads-up about it via a logged warning.
        assert "spans 2 databases" in caplog.text
        assert "[2, 4]" in caplog.text

    def test_field_refs_in_parameter_mappings_target_are_substituted(self, src_lookup):
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
        assert text.count("collection_id: ${ collection_id }") == 2

    def test_dashcard_viz_settings_with_stale_field_id_does_not_raise(self, src_lookup):
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
        # `dashboard_name` is a standalone string placeholder (replaces the
        # whole value, not a substring), so it's emitted with `| tojson`
        # so the renderer outputs a quoted YAML string.  Without tojson, a
        # user value like 'My Clone #2' would have '#2' eaten as a YAML
        # comment at re-parse time.
        d = {
            "name": "MST Payments",
            "dashcards": [],
        }
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "name: ${ dashboard_name | tojson }" in text
        assert "MST Payments" not in text

    def test_dashboard_name_with_yaml_metachars_survives_round_trip(self, src_lookup):
        # Regression: '#' in a user-supplied dashboard name used to be
        # stripped because the rendered YAML treated everything after '#'
        # as a comment.  tojson on the standalone placeholder keeps it
        # intact through the JSON quoting.
        d = {"name": "Some Source Name", "dashcards": []}
        cleaned, ph = jinjaify(copy.deepcopy(d), src_lookup)
        text = emit_template_yaml(cleaned, ph)
        env = make_jinja_env(src_lookup)
        rendered = render_template_text(
            text,
            {"dashboard_name": "(CCJPA) Clone #2: special - test"},
            env,
        )
        assert rendered["name"] == "(CCJPA) Clone #2: special - test"

    def test_no_templatize_name_preserves_literal(self, src_lookup):
        d = {"name": "MST Payments", "dashcards": []}
        cleaned, ph = jinjaify(copy.deepcopy(d), src_lookup, templatize_name=False)
        text = emit_template_yaml(cleaned, ph)
        assert "name: MST Payments" in text
        assert "${ dashboard_name }" not in text

    def test_dashboard_without_name_does_not_emit_dashboard_name_var(self, src_lookup):
        # Templatize-name is opportunistic: no top-level name -> no var.
        d = {"dashcards": []}
        text = self._walk_for_jinja_text(d, src_lookup)
        assert "${ dashboard_name }" not in text

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

    def test_multiple_source_collections_is_warning_not_error(self, src_lookup, caplog):
        # Dashboards routinely have cards spread across several collections
        # (e.g. CCJPA: dashboard in one collection, supporting cards in
        # others).  Since every collection_id in the template resolves to
        # the same `${ collection_id }` placeholder, all cards land in
        # whichever single target collection the user picks at apply time.
        # So this is informational, not fatal.
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
        with caplog.at_level(logging.WARNING):
            cleaned, _ = jinjaify(d, src_lookup)
        # Both collection_id slots get rewritten to the same placeholder
        # expression, so apply will route everything to one target.
        assert cleaned["collection_id"].startswith("__JINJAEXPR_")
        assert cleaned["dashcards"][0]["card"]["collection_id"].startswith(
            "__JINJAEXPR_"
        )
        # And the user got a heads-up about it via a logged warning.
        assert "spans 2 collections" in caplog.text
        assert "145" in caplog.text and "999" in caplog.text


# --------------------------------------------------------------------------- #
# emit_template_yaml() -- placeholder substitution + Jinja round-trip
# --------------------------------------------------------------------------- #


class TestEmitTemplateYaml:
    def test_jinja_expression_stays_unquoted_so_int_survives_round_trip(
        self,
        src_lookup,
        tgt_meta,
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
        assert "database: ${ database_id }" in text
        assert "database: '${ database_id }'" not in text
        assert 'database: "${ database_id }"' not in text

        # And after Jinja rendering with a real int, YAML parses it as int.
        env = make_jinja_env(lambda _: tgt_meta)
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
