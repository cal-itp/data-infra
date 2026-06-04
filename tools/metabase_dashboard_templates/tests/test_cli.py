"""Smoke tests for the cli entry point (click commands)."""

import copy
import json
from unittest.mock import MagicMock

import pytest
from cli import cli
from click.testing import CliRunner
from metabase_flow.template_export import emit_template_yaml, jinjaify

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
        import cli as mod

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
        import cli as mod

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
