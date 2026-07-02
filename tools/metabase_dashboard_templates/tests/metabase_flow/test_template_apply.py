"""Tests for metabase_flow.template_apply.

Covers the template -> dashboard direction: the Jinja env helpers
(make_jinja_env), render_template_text, the POST/PUT payload builders, and
apply_dashboard against a mocked HTTP session.
"""

import copy
from unittest.mock import MagicMock

import pytest
from metabase_flow.constants import STRIP_CARD_KEYS
from metabase_flow.template_apply import (
    apply_dashboard,
    build_card_payload,
    build_dashcard_for_put,
    make_jinja_env,
    render_template_text,
)
from metabase_flow.template_export import emit_template_yaml, jinjaify

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
# make_jinja_env(): Jinja-exposed helpers
# --------------------------------------------------------------------------- #


class TestJinjaHelpers:
    def test_get_table_id_with_qualified_name(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string('${ get_table_id(database_id, "mart_gtfs.dim_stops") }')
        assert tpl.render(database_id=3) == "325"

    def test_get_table_id_with_unqualified_unique_name(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string('${ get_table_id(database_id, "dim_stops") }')
        assert tpl.render(database_id=3) == "325"

    def test_get_table_id_unknown_table_raises(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        tpl = env.from_string(
            '${ get_table_id(database_id, "mart_gtfs.does_not_exist") }'
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
        tpl = env.from_string('${ get_table_id(database_id, "users") }')
        with pytest.raises(Exception, match="ambiguous"):
            tpl.render(database_id=99)

    def test_get_field_id_qualified(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        out = env.from_string(
            '${ get_field_id(database_id, "mart_gtfs.dim_stops", "feed_key") }'
        ).render(database_id=3)
        assert out == "8256"

    def test_get_field_id_unknown_field_raises(self, tgt_lookup):
        env = make_jinja_env(tgt_lookup)
        with pytest.raises(Exception, match="not found in target DB"):
            env.from_string(
                '${ get_field_id(database_id, "mart_gtfs.dim_stops", "nope") }'
            ).render(database_id=3)

    def test_metadata_lookup_is_cached_per_db_id(self, tgt_meta):
        calls = []

        def lookup(db_id):
            calls.append(db_id)
            return tgt_meta

        env = make_jinja_env(lookup)
        tpl1 = env.from_string('${ get_table_id(database_id, "dim_stops") }')
        tpl2 = env.from_string(
            '${ get_field_id(database_id, "dim_stops", "feed_key") }'
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
        apply_dashboard(sess, "https://m.example", spec)

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
        apply_dashboard(sess, "https://m.example", spec)
        _, put_body = calls["puts"][0]
        dc = put_body["dashcards"][0]
        assert dc["card_id"] == 501
        assert dc["parameter_mappings"][0]["card_id"] == 501

    def test_missing_top_level_name_raises(self):
        spec = {"description": "no name", "dashcards": []}
        sess, _ = _make_fake_session()
        with pytest.raises(Exception, match="name"):
            apply_dashboard(sess, "https://m.example", spec)

    def test_non_virtual_dashcard_without_card_block_raises(self):
        spec = {
            "name": "X",
            "dashcards": [{"row": 0, "col": 0, "size_x": 1, "size_y": 1}],
        }
        sess, _ = _make_fake_session()
        with pytest.raises(Exception, match="card"):
            apply_dashboard(sess, "https://m.example", spec)
