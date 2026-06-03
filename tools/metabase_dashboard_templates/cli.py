r"""
Manage Metabase dashboards as Jinja-templated YAML files.

Two subcommands:

  dashboard-to-template
    Export a Metabase dashboard to a YAML template file.  Strips
    server-generated fields and replaces instance-specific ids
    (database / table / field ids) with Jinja2 expressions that look
    them up on the target instance at apply time.

  template-to-dashboard
    Render a Jinja-templated YAML file with a user-supplied context
    and create a new Metabase dashboard from the result.

A template file is a Jinja2-templated YAML document.  At render time the
context is expected to provide `database_id` (the target Metabase database
connection id) and `collection_id` (the target collection id), and the
helpers `get_table_id` / `get_field_id` are exposed to look up
instance-specific ids by name.

Usage examples
--------------

  # Export dashboard 9 to a template
  python tools/metabase_dashboard_templates/cli.py dashboard-to-template \
      --metabase-url https://metabase-staging.dds.dot.ca.gov \
      --metabase-api-key "$METABASE_API_KEY_RAW" \
      --dashboard-id 9 \
      --template-file dashboard_9.yml

  # Apply that template against DB connection 3, collection 22
  python tools/metabase_dashboard_templates/cli.py template-to-dashboard \
      --metabase-url https://metabase-staging.dds.dot.ca.gov \
      --metabase-api-key "$METABASE_API_KEY_RAW" \
      --template-file dashboard_9.yml \
      --template-context '{"database_id": 3, "collection_id": 22}'

Implementation notes
--------------------

YAML cannot natively represent unquoted Jinja expressions like
`{{ database_id }}` (the leading `{` is parsed as flow-mapping syntax).
Two approaches are common; this file uses approach (a):

  (a) "Jinja-then-YAML": the file is read as text, rendered with Jinja,
      then yaml.safe_load() parses the result.  Bare expressions are
      written into the source as `database: {{ database_id }}`, which is
      not valid YAML standalone but is valid after rendering.  This is
      the same model Ansible uses.

  (b) "YAML-with-tags": embed expressions in tagged scalars and resolve
      them post-parse.  Heavier; not used here.

To produce a (a)-style file with PyYAML, this module replaces id slots
with sentinel strings (`__JINJAEXPR_N__`) during the walk, dumps via
yaml.safe_dump, then post-processes the text to swap each sentinel
(plus any quotes PyYAML may have wrapped it in) for the corresponding
`{{ ... }}` expression.
"""

from __future__ import annotations

import json
import logging
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Any, Callable

import click
import jinja2
import jinja2.meta
import requests
import yaml

# cli.py is the CLI layer and owns all click usage.  The reusable core modules
# (gcp_secrets, read_metabase, and the export/apply logic) stay click-free:
# they raise plain exceptions and log via the stdlib `logging` module so they
# carry no CLI dependency and can be reused by other tools.  This layer catches
# those exceptions and re-raises them as click.ClickException so the CLI prints
# a clean message instead of a traceback.
from constants import (
    POST_DASHBOARD_KEYS,
    STRIP_CARD_KEYS,
    STRIP_DASHBOARD_KEYS,
    TEMPLATES_DIR,
)
from environments import ENV_LABELS, ENVIRONMENTS
from errors import TemplateError
from gcp_secrets import SecretAccessError, fetch_secret_from_gcp
from read_metabase import (
    existing_dashboards_with_name,
    fetch_database_metadata,
    list_collections,
    list_dashboards,
    list_databases,
    make_session,
)
from template_export import (
    _find_source_card_int_refs,
    _find_source_card_name_refs,
    _resolve_source_card_names_in_place,
    export_dashboard_to_template_text,
    is_virtual_dashcard,
    strip,
)

# ---------------------------------------------------------------------------
# TEMPLATE -> DASHBOARD: render Jinja, parse YAML, apply
# ---------------------------------------------------------------------------


def make_jinja_env(
    metadata_lookup: Callable[[int], dict],
) -> jinja2.Environment:
    """Build a Jinja Environment that exposes get_table_id / get_field_id.

    `metadata_lookup` takes a Metabase database_id and returns the metadata
    dict produced by fetch_database_metadata().  Decoupling this lets tests
    pass in a stubbed lookup without an HTTP session.
    """
    cache: dict[int, dict] = {}

    def meta(db_id: int) -> dict:
        if db_id not in cache:
            cache[db_id] = metadata_lookup(db_id)
        return cache[db_id]

    def split_table(table_name: str, m: dict) -> tuple[str, str]:
        if "." in table_name:
            schema, name = table_name.split(".", 1)
            if (schema, name) not in m["table_to_id"]:
                raise KeyError(
                    f"table {schema}.{name!r} not found in target DB metadata"  # noqa: E713
                )
            return schema, name
        candidates = [k for k in m["table_to_id"] if k[1] == table_name]
        if not candidates:
            raise KeyError(
                f"table {table_name!r} not found in target DB metadata"  # noqa: E713
            )  # noqa: E713
        if len(candidates) > 1:
            schemas = sorted({s for s, _ in candidates})
            raise KeyError(
                f"table name {table_name!r} is ambiguous across schemas {schemas}; "  # noqa: 702
                "qualify it as 'schema.table'"
            )
        return candidates[0]

    def get_table_id(database_id: int, table_name: str) -> int:
        m = meta(database_id)
        schema, name = split_table(table_name, m)
        return m["table_to_id"][(schema, name)]

    def get_field_id(database_id: int, table_name: str, field_name: str) -> int:
        m = meta(database_id)
        schema, name = split_table(table_name, m)
        key = (schema, name, field_name)
        if key not in m["field_to_id"]:
            raise KeyError(
                f"field {schema}.{name}.{field_name} not found in target DB metadata"  # noqa: E713
            )
        return m["field_to_id"][key]

    env = jinja2.Environment(  # nosec B701
        undefined=jinja2.StrictUndefined,
        keep_trailing_newline=True,
    )
    # NOTE: We are ignoring B701 above because (1) we are not generating
    # runnable code, just dashboard specs, and (2) the Jinja expressions are
    # under user control, so the risk of code injection is minimal.  Using
    # StrictUndefined helps catch template errors.
    env.globals["get_table_id"] = get_table_id
    env.globals["get_field_id"] = get_field_id
    return env


def render_template_text(
    template_text: str,
    context: dict,
    env: jinja2.Environment,
) -> dict:
    rendered = env.from_string(template_text).render(**context)
    return yaml.safe_load(rendered)


def build_card_payload(card: dict) -> dict:
    """POST /api/card body.  The template is expected to be free of
    server-generated keys, but we strip again defensively in case the
    user pasted in a raw GET payload."""
    payload = strip(card, STRIP_CARD_KEYS)
    payload.setdefault("visualization_settings", {})
    payload.setdefault("parameters", [])
    payload.setdefault("parameter_mappings", [])
    return payload


def build_dashcard_for_put(
    source_dc: dict,
    neg_id: int,
    new_card_id: int | None,
    tab_id_remap: dict[int, int] | None = None,
    default_tab_neg_id: int | None = None,
) -> dict:
    pmappings = source_dc.get("parameter_mappings") or []
    # In Metabase's data model, parameter_mappings[].card_id always points
    # at the dashcard's own card; the source-dashboard id no longer applies
    # once we've created a fresh card on the target.  Without this rewrite,
    # Metabase silently drops the mappings and filters appear unwired.
    if new_card_id is not None and pmappings:
        pmappings = [{**pm, "card_id": new_card_id} for pm in pmappings]
    out = {
        "id": neg_id,
        "row": source_dc["row"],
        "col": source_dc["col"],
        "size_x": source_dc["size_x"],
        "size_y": source_dc["size_y"],
        "parameter_mappings": pmappings,
        "visualization_settings": source_dc.get("visualization_settings") or {},
        "series": source_dc.get("series") or [],
    }
    if new_card_id is not None:
        out["card_id"] = new_card_id
    # If the target dashboard has tabs, every dashcard must declare which
    # tab it belongs to (Metabase rejects the PUT with "This dashboard has
    # tab, makes sure every card has a tab" otherwise).  Map the source tab
    # id to the matching negative tab id in this PUT.  If the source dc
    # doesn't have a tab id, or the id isn't in the remap, fall back to the
    # default (typically the first tab).
    if default_tab_neg_id is not None:
        original_tab_id = source_dc.get("dashboard_tab_id")
        if (
            isinstance(original_tab_id, int)
            and tab_id_remap
            and original_tab_id in tab_id_remap
        ):
            out["dashboard_tab_id"] = tab_id_remap[original_tab_id]
        else:
            out["dashboard_tab_id"] = default_tab_neg_id
    return out


def _check_metabase_response(
    r: requests.Response,
    *,
    action: str,
    payload: dict | None = None,
) -> None:
    """Raise a ClickException with Metabase's response body if `r` is not 2xx.

    Metabase's 4xx/5xx bodies almost always carry an actionable JSON
    `{"message": "...", "errors": {...}}` -- but the default
    `raise_for_status()` discards it.  This surfaces it, plus a short tag
    naming which step failed (e.g. "POST /api/card for 'Total transactions'").
    """
    if r.ok:
        return
    body_text = r.text or ""
    try:
        body = r.json()
        body_pretty = json.dumps(body, indent=2)[:2000]
    except (ValueError, json.JSONDecodeError):
        body_pretty = body_text[:2000]

    payload_hint = ""
    if payload is not None:
        # Show the card/dashboard name we were trying to create so the user
        # can find the offending source card in the template.  Don't dump
        # the whole payload -- card payloads are huge.
        name = payload.get("name")
        if name:
            payload_hint = f"  Item: {name!r}\n"

    raise click.ClickException(
        f"Metabase rejected request: {action}\n"
        f"  HTTP {r.status_code} {r.reason}\n"
        f"{payload_hint}"
        f"  Response body:\n{body_pretty}"
    )


def apply_dashboard(
    session: requests.Session,
    base_url: str,
    spec: dict,
) -> dict:
    """Create a new dashboard from a fully-rendered template spec.

    Always creates fresh -- in-place update of an existing dashboard was
    removed because the destructive PUT pattern (full dashcards replace,
    plus orphan cards left in the collection) made it too easy to clobber
    a deployed agency dashboard.  Re-apply the template against a fresh
    collection if you need a do-over.
    """
    spec = strip(spec, STRIP_DASHBOARD_KEYS)
    supporting_cards = spec.pop("supporting_cards", None) or []
    dashcards = spec.pop("dashcards", []) or []
    source_tabs = spec.pop("tabs", None) or []

    # Pre-flight: if a non-archived dashboard with this name already exists
    # in the target collection, prompt before proceeding.  Metabase allows
    # duplicate names, so a second apply would silently create a "MyDash
    # (2)"-style sibling -- which is almost never what the user wants.
    # Gated behind y/N rather than a hard abort so re-running an apply
    # against an intentional staging collection still works.  Runs BEFORE
    # any cards are POSTed so backing out leaves no orphan cards.
    target_name = spec.get("name")
    target_collection_id = spec.get("collection_id")
    if isinstance(target_name, str) and isinstance(target_collection_id, int):
        duplicates = existing_dashboards_with_name(
            session, base_url, target_name, target_collection_id
        )
        if duplicates:
            existing_summary = ", ".join(f"id {d.get('id')}" for d in duplicates)
            click.confirm(
                f"\nA dashboard named {target_name!r} already exists in the "
                f"target collection ({existing_summary}).  Continuing will "
                "create a second dashboard with the same name (Metabase "
                "permits duplicates).  Proceed?",
                default=False,
                abort=True,
            )

    # If the source dashboard uses Tabs, build a side table mapping each
    # source tab id to a negative id we'll send in the PUT.  Every dashcard
    # gets its `dashboard_tab_id` remapped through this; without it, Metabase
    # rejects the PUT with "This dashboard has tab, makes sure every card
    # has a tab".  Tabs are sorted by `position` so the first tab gets -1,
    # matching the order users see in the Metabase UI.
    tab_id_remap: dict[int, int] = {}
    tabs_for_put: list[dict] = []
    default_tab_neg_id: int | None = None
    if source_tabs:
        sorted_tabs = sorted(source_tabs, key=lambda t: t.get("position", 0))
        for i, tab in enumerate(sorted_tabs, start=1):
            neg_id = -i
            original_id = tab.get("id")
            if isinstance(original_id, int):
                tab_id_remap[original_id] = neg_id
            tabs_for_put.append(
                {
                    "id": neg_id,
                    "name": tab.get("name") or f"Tab {i}",
                    "position": tab.get("position", i - 1),
                }
            )
        default_tab_neg_id = tabs_for_put[0]["id"]

    # Step 0: POST supporting cards (the saved questions the dashboard's
    # cards build on top of) in dependency order, then build a name->id map
    # we can use to rewrite every `source-card-name: "X"` further down.
    name_to_new_id: dict[str, int] = {}
    if supporting_cards:
        click.echo(f"Creating {len(supporting_cards)} supporting card(s)...", err=True)
        remaining = list(supporting_cards)
        # O(N^2) topo: each pass POSTs any card whose source-card-name refs
        # are already resolved.  Halts on a cycle or a missing dependency.
        while remaining:
            ready: list[dict] = []
            blocked: list[dict] = []
            for card in remaining:
                refs = _find_source_card_name_refs(card)
                if refs.issubset(name_to_new_id.keys()):
                    ready.append(card)
                else:
                    blocked.append(card)
            if not ready:
                missing: set[str] = set()
                for card in blocked:
                    missing |= _find_source_card_name_refs(card)
                missing -= name_to_new_id.keys()
                blocked_names = [c.get("name", "<unnamed>") for c in blocked]
                raise click.ClickException(
                    "Cannot resolve supporting card dependencies.  "
                    f"Stuck on {blocked_names!r}; missing refs: {sorted(missing)}.  "
                    "Likely a dependency cycle, or a supporting card was "
                    "dropped at export time."
                )
            for card in ready:
                # Deep-copy via JSON round-trip so we don't mutate the
                # source list and lose info if a later step needs it.
                resolved = json.loads(json.dumps(card))
                _resolve_source_card_names_in_place(resolved, name_to_new_id)
                payload = build_card_payload(resolved)
                r = session.post(f"{base_url}/api/card", json=payload)
                _check_metabase_response(
                    r, action="POST /api/card (supporting)", payload=payload
                )
                c = r.json()
                name_to_new_id[card["name"]] = c["id"]
                click.echo(f"  created supporting card {c['id']}: {c['name']!r}")
            remaining = blocked

    # Rewrite every source-card-name / card_name__ ref in the remaining spec
    # (dashcards and their nested queries) into a live source-card int.  If
    # there are no supporting cards, this is a fast no-op.
    if name_to_new_id:
        _resolve_source_card_names_in_place(spec, name_to_new_id)
        for dc in dashcards:
            _resolve_source_card_names_in_place(dc, name_to_new_id)

    # Pre-flight: catch templates exported before source-card support landed.
    # After the rewrite, the only int `source-card` refs in the spec should
    # be live ones we just created (i.e. values from name_to_new_id).
    # Anything else points at a card on the source instance and is
    # guaranteed to FK-violate on POST -- surface it clearly instead.
    leftover_int_refs = _find_source_card_int_refs(
        {"_dc": dashcards, "_spec": spec}
    ) - set(name_to_new_id.values())
    if leftover_int_refs:
        raise click.ClickException(
            f"Template references source-card int ids "
            f"{sorted(leftover_int_refs)} that have no matching "
            "supporting_cards entry.  These point at saved questions on the "
            "source Metabase instance and will not exist on the destination.\n"
            "This template was exported before the tool supported "
            "source-card resolution.  Re-export the source dashboard with "
            "the current `dashboard-to-template` command; the new template "
            "will embed the referenced cards under a `supporting_cards:` "
            "top-level key, and the apply step will create them first."
        )

    # Step 1: plan card creation.
    plan: list[tuple[dict, int]] = []  # (source_dashcard, card_index | -1 virtual)
    new_cards: list[dict] = []
    for dc in dashcards:
        if is_virtual_dashcard(dc):
            plan.append((dc, -1))
        else:
            card = dc.get("card")
            if not isinstance(card, dict) or not card.get("name"):
                raise click.ClickException(
                    "non-virtual dashcard is missing a `card` block with a name"
                )
            new_cards.append(build_card_payload(card))
            plan.append((dc, len(new_cards) - 1))

    # Step 2: POST cards.
    created_card_ids: list[int] = []
    for payload in new_cards:
        r = session.post(f"{base_url}/api/card", json=payload)
        _check_metabase_response(r, action="POST /api/card", payload=payload)
        c = r.json()
        created_card_ids.append(c["id"])
        click.echo(f"  created card {c['id']}: {c['name']!r}")

    # Step 3: POST dashboard shell.
    post_body = {
        k: spec[k] for k in POST_DASHBOARD_KEYS if k in spec and spec[k] is not None
    }
    if "name" not in post_body:
        raise click.ClickException("template is missing a top-level `name`")
    r = session.post(f"{base_url}/api/dashboard/", json=post_body)
    _check_metabase_response(r, action="POST /api/dashboard/", payload=post_body)
    dashboard = r.json()
    dashboard_id = dashboard["id"]
    click.echo(f"  created dashboard {dashboard_id}: {dashboard['name']!r}")

    # Step 4: PUT /api/dashboard/{id} to attach tabs + dashcards.
    dashcards_put = [
        build_dashcard_for_put(
            src_dc,
            neg_id=-(i + 1),
            new_card_id=created_card_ids[idx] if idx >= 0 else None,
            tab_id_remap=tab_id_remap,
            default_tab_neg_id=default_tab_neg_id,
        )
        for i, (src_dc, idx) in enumerate(plan)
    ]
    put_body = dict(spec)  # everything from the template that survived strip
    put_body["dashcards"] = dashcards_put
    if tabs_for_put:
        # Metabase resolves negative tab ids to real ids server-side, then
        # links each dashcard's `dashboard_tab_id` (also negative) to the
        # matching tab.  Both arrays must be in the same PUT for the
        # cross-references to resolve atomically.
        put_body["tabs"] = tabs_for_put
    r = session.put(f"{base_url}/api/dashboard/{dashboard_id}", json=put_body)
    _check_metabase_response(
        r,
        action=f"PUT /api/dashboard/{dashboard_id} (attach {len(dashcards_put)} dashcards)",
    )
    final = r.json()
    click.echo(f"  attached {len(dashcards_put)} dashcards")
    click.echo(f"View: {base_url}/dashboard/{dashboard_id}")
    return final


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


@click.group(context_settings={"help_option_names": ["-h", "--help"]})
@click.option(
    "--metabase-url",
    default=None,
    envvar="METABASE_URL",
    help="Base URL of the Metabase instance (env: METABASE_URL). "
    "Not required for the `interactive` command.",
)
@click.option(
    "--metabase-api-key",
    default=None,
    envvar="METABASE_API_KEY_RAW",
    help="Metabase API key as a literal string (env: METABASE_API_KEY_RAW). "
    "Mutually exclusive with --gcp-secret. "
    "Not required for the `interactive` command.",
)
@click.option(
    "--gcp-secret",
    default=None,
    envvar="METABASE_GCP_SECRET",
    help=(
        "GCP Secret Manager resource name holding the Metabase API key "
        "(env: METABASE_GCP_SECRET). "
        "Format: projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION. "
        "Mutually exclusive with --metabase-api-key. "
        "Not required for the `interactive` command."
    ),
)
@click.pass_context
def cli(
    ctx: click.Context,
    metabase_url: str | None,
    metabase_api_key: str | None,
    gcp_secret: str | None,
) -> None:
    """Manage Metabase dashboards as Jinja-templated YAML files."""
    ctx.ensure_object(dict)
    # The reusable core logs progress/warnings via the stdlib `logging` module
    # instead of printing; route those records to stderr for CLI users.
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stderr)
    # Stash raw args; subcommands that need a session call _ensure_session().
    # `interactive` picks its own url+key based on the user's menu choices
    # and skips _ensure_session entirely.
    ctx.obj["raw_url"] = metabase_url
    ctx.obj["raw_api_key"] = metabase_api_key
    ctx.obj["raw_gcp_secret"] = gcp_secret


def _ensure_session(ctx: click.Context) -> None:
    """Materialize ctx.obj['session'] + ctx.obj['base_url'] from group args.

    Validates that --metabase-url is set and that exactly one of
    --metabase-api-key / --gcp-secret was provided.  Idempotent: a second
    call is a no-op once the session is built.
    """
    if "session" in ctx.obj:
        return
    url = ctx.obj.get("raw_url")
    api_key = ctx.obj.get("raw_api_key")
    gcp_secret = ctx.obj.get("raw_gcp_secret")
    if not url:
        raise click.UsageError(
            "--metabase-url is required for this command (env: METABASE_URL)."
        )
    if api_key and gcp_secret:
        raise click.UsageError(
            "--metabase-api-key and --gcp-secret are mutually exclusive."
        )
    if not api_key and not gcp_secret:
        raise click.UsageError(
            "Provide either --metabase-api-key (env: METABASE_API_KEY_RAW) "
            "or --gcp-secret (env: METABASE_GCP_SECRET)."
        )
    if gcp_secret:
        click.echo(f"Fetching Metabase API key from GCP: {gcp_secret}", err=True)
        try:
            api_key = fetch_secret_from_gcp(gcp_secret)
        except SecretAccessError as exc:
            raise click.ClickException(str(exc))
    ctx.obj["session"] = make_session(api_key)
    ctx.obj["base_url"] = url.rstrip("/")


def _confirm_embedded_substitution(literal: str, surrounding: str) -> bool:
    """resolve_embedded strategy for the export pipeline: a substitution
    literal landed inside a larger token; ask the user whether to substitute
    it anyway.  jinjaify defaults to "no" when no strategy is supplied."""
    return click.confirm(
        f"\n  Substitution {literal!r} would replace text inside the larger "
        f"token {surrounding!r}.  Substitute here?",
        default=False,
    )


@cli.command("dashboard-to-template")
@click.option("--dashboard-id", type=int, required=True, help="Source dashboard id.")
@click.option(
    "--template-file",
    type=click.Path(dir_okay=False, writable=True),
    required=True,
    help="Output path.  Use '-' to write to stdout.",
)
@click.option(
    "--templatize-name/--no-templatize-name",
    default=True,
    show_default=True,
    help="If set, replace the top-level dashboard name with "
    "{{ dashboard_name }} so each agency apply can pass its own. "
    "Use --no-templatize-name for migration-style 1:1 copies.",
)
@click.option(
    "--substitution",
    "substitutions",
    multiple=True,
    metavar="LITERAL=VARNAME",
    help="Replace literal text with a Jinja variable in every string field. "
    "Repeatable.  Example: --substitution 'MST=agency_short' replaces "
    "every 'MST' in card names, headings, and descriptions with "
    "{{ agency_short }} in the template.",
)
@click.pass_context
def cmd_dashboard_to_template(
    ctx: click.Context,
    dashboard_id: int,
    template_file: str,
    templatize_name: bool,
    substitutions: tuple[str, ...],
) -> None:
    """Export a dashboard to a Jinja-templated YAML file."""
    _ensure_session(ctx)
    session: requests.Session = ctx.obj["session"]
    base_url: str = ctx.obj["base_url"]

    parsed_subs: list[tuple[str, str]] = []
    for s in substitutions:
        if "=" not in s:
            raise click.ClickException(
                f"--substitution must be LITERAL=VARNAME; got {s!r}"
            )
        literal, varname = s.split("=", 1)
        if not literal:
            raise click.ClickException(
                f"--substitution LITERAL must be non-empty; got {s!r}"
            )
        if not varname.isidentifier():
            raise click.ClickException(
                f"--substitution VARNAME must be a valid identifier; got {varname!r}"
            )
        parsed_subs.append((literal, varname))

    try:
        text, placeholder_count = export_dashboard_to_template_text(
            session,
            base_url,
            dashboard_id,
            templatize_name=templatize_name,
            substitutions=parsed_subs,
            resolve_embedded=_confirm_embedded_substitution,
        )
    except TemplateError as exc:
        raise click.ClickException(str(exc))

    if template_file == "-":
        click.echo(text, nl=False)
    else:
        Path(template_file).parent.mkdir(parents=True, exist_ok=True)
        with open(template_file, "w") as f:
            f.write(text)
        click.echo(
            f"Wrote template ({placeholder_count} expressions) -> {template_file}"
        )


@cli.command("template-to-dashboard")
@click.option(
    "--template-file",
    type=click.Path(exists=True, dir_okay=False),
    required=True,
    help="Path to the Jinja-templated YAML file.",
)
@click.option(
    "--template-context",
    default="{}",
    show_default=True,
    help='JSON object passed to Jinja (e.g. \'{"database_id": 3, "collection_id": 22}\').',
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Render the template and print the resulting dashboard spec without writing.",
)
@click.pass_context
def cmd_template_to_dashboard(
    ctx: click.Context,
    template_file: str,
    template_context: str,
    dry_run: bool,
) -> None:
    """Render a template and create a new dashboard from it."""
    _ensure_session(ctx)
    session: requests.Session = ctx.obj["session"]
    base_url: str = ctx.obj["base_url"]

    try:
        context = json.loads(template_context)
    except json.JSONDecodeError as e:
        raise click.ClickException(f"--template-context is not valid JSON: {e}")
    if not isinstance(context, dict):
        raise click.ClickException("--template-context must be a JSON object")

    def fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(session, base_url, db_id)

    env = make_jinja_env(fetch_meta)

    with open(template_file) as f:
        template_text = f.read()
    spec = render_template_text(template_text, context, env)

    if dry_run:
        click.echo(json.dumps(spec, indent=2, default=str))
        return

    apply_dashboard(session, base_url, spec)


# ---------------------------------------------------------------------------
# Interactive wizard
# ---------------------------------------------------------------------------


def _ensure_templates_dir() -> Path:
    """Make sure TEMPLATES_DIR exists; create it (with a .gitkeep) if not.

    Returning the path keeps callers from re-deriving it.
    """
    if not TEMPLATES_DIR.exists():
        click.echo(f"Creating templates directory: {TEMPLATES_DIR}", err=True)
        TEMPLATES_DIR.mkdir(parents=True, exist_ok=True)
        # Drop a .gitkeep so the empty directory survives a fresh clone.
        (TEMPLATES_DIR / ".gitkeep").touch()
    elif not TEMPLATES_DIR.is_dir():
        raise click.ClickException(
            f"Expected templates directory at {TEMPLATES_DIR}, but a file "
            "with that name already exists.  Move or rename it and re-run."
        )
    return TEMPLATES_DIR


def _list_template_files() -> list[Path]:
    """Return existing *.yml / *.yaml templates in TEMPLATES_DIR, sorted."""
    if not TEMPLATES_DIR.is_dir():
        return []
    return sorted(
        [*TEMPLATES_DIR.glob("*.yml"), *TEMPLATES_DIR.glob("*.yaml")],
        key=lambda p: p.name.lower(),
    )


def _prompt_for_substitutions() -> list[tuple[str, str]]:
    """Interactively collect (literal, varname) pairs for the substitution
    feature.  Returns [] if the user declines.

    Loops until the user says no.  Validates that each VARNAME is a valid
    Python identifier (so it can be used as a Jinja variable name); on
    failure, re-prompts for the same row rather than discarding the literal.

    The non-interactive subcommand exposes the same machinery via
    `--substitution LITERAL=VARNAME` (repeatable).  This helper is the
    interactive equivalent for the wizard.
    """
    if not click.confirm(
        "\nSwap any literal text for Jinja variables in the template?\n"
        "  Useful for agency identifiers baked into SQL filters (e.g.\n"
        "  'ccjpa' or 'MST'), card titles, or descriptions.  Each VARNAME\n"
        "  becomes a prompt at apply time.",
        default=False,
    ):
        return []

    click.echo(
        "Enter LITERAL -> VARNAME pairs.  Every occurrence of LITERAL "
        "anywhere in the template (card SQL, titles, descriptions, "
        "headings) is replaced with `{{ VARNAME }}` and resolved at apply."
    )
    parsed_subs: list[tuple[str, str]] = []
    while True:
        literal = click.prompt(
            "  Literal text to replace", type=str, default="", show_default=False
        ).strip()
        if not literal:
            click.echo("  (empty literal -- skipping)", err=True)
        else:
            while True:
                varname = click.prompt(
                    "  Replace with Jinja variable named", type=str
                ).strip()
                if varname.isidentifier():
                    break
                click.echo(
                    f"  {varname!r} is not a valid identifier "
                    "(letters/digits/underscores only, can't start with a "
                    "digit).  Try again.",
                    err=True,
                )
            parsed_subs.append((literal, varname))
            click.echo(f"    queued: {literal!r} -> {{{{ {varname} }}}}")
        if not click.confirm("  Add another?", default=False):
            break
    return parsed_subs


def _slugify(name: str) -> str:
    """Turn a dashboard name into a filename-safe slug.

    Lowercases, collapses any run of non-[a-z0-9] into a single dash, and
    strips leading/trailing dashes.  Non-ASCII chars (e.g. accented Latin)
    are treated as separators -- lossy but predictable.  Empty result
    falls back to 'dashboard' so we never emit "<id>-.yml".

    Examples:
        '(CCJPA) Reconciliation dashboard (LittlePay to Elavon)'
            -> 'ccjpa-reconciliation-dashboard-littlepay-to-elavon'
        'Payments Overview'   -> 'payments-overview'
        '!!!'                 -> 'dashboard'
    """
    slug = re.sub(r"[^a-z0-9]+", "-", name.lower()).strip("-")
    return slug or "dashboard"


def _connect_env(env_name: str) -> tuple[requests.Session, str]:
    """Pull `env_name`'s URL + GCP secret out of ENVIRONMENTS, fetch the API
    key, and return (session, base_url)."""
    cfg = ENVIRONMENTS[env_name]
    label = ENV_LABELS.get(env_name, env_name)
    click.echo(f"Fetching API key from GCP for {label}...", err=True)
    try:
        api_key = fetch_secret_from_gcp(cfg["gcp_secret"])
    except SecretAccessError as exc:
        raise click.ClickException(str(exc))
    return make_session(api_key), cfg["url"].rstrip("/")


# Names that the Jinja env supplies as callables rather than context values --
# they always appear "undeclared" to find_undeclared_variables but we never
# prompt the user for them.
TEMPLATE_BUILTIN_NAMES: set[str] = {"get_table_id", "get_field_id"}


def _detect_template_vars(template_text: str) -> set[str]:
    """Return the set of context variables a template references.

    Strips out the helper callables (get_table_id, get_field_id) since those
    come from the Jinja env, not the user-supplied context.
    """
    parsed = jinja2.Environment().parse(template_text)  # nosec B701
    return jinja2.meta.find_undeclared_variables(parsed) - TEMPLATE_BUILTIN_NAMES


@cli.command("interactive")
@click.pass_context
def cmd_interactive(ctx: click.Context) -> None:
    """Interactive wizard: copy a dashboard between an existing template,
    Metabase Staging, Metabase Prod, and a YAML file in the templates dir.

    On start, ensures TEMPLATES_DIR (next to this script) exists and lists
    any *.yml / *.yaml files inside it so the user can pick one as the
    source -- skipping a Metabase round-trip when a template has already
    been exported.

    Reads Metabase API keys for each instance from GCP Secret Manager via
    Application Default Credentials.  Configure the URL + secret resource
    name per environment in ENVIRONMENTS in environments.py.
    """
    templates_dir = _ensure_templates_dir()
    existing_templates = _list_template_files()

    # ----- Step 1: source -----
    # Source menu is dynamic: option 1 only appears if there's at least one
    # template to pick from.  Build (key, label) pairs in display order so
    # the numbering and dispatch stay in sync.
    src_options: list[tuple[str, str]] = []
    if existing_templates:
        src_options.append(("template", f"Existing template in {templates_dir.name}/"))
    src_options.append(("staging", "Metabase Staging"))
    src_options.append(("prod", "Metabase Prod"))

    click.echo("Where would you like to copy a dashboard from?")
    for i, (_, label) in enumerate(src_options, start=1):
        click.echo(f"  {i} = {label}")
    src_choice = click.prompt(
        "Choice",
        type=click.Choice([str(i) for i in range(1, len(src_options) + 1)]),
        show_choices=False,
    )
    src_kind = src_options[int(src_choice) - 1][0]

    # Per-branch outputs feeding step 3: the template text to apply, a name
    # to use as the default new-dashboard name, and whether "template only"
    # remains a meaningful destination choice (it doesn't if the source
    # already is a template -- we'd just be copying a file).
    template_text: str
    src_dashboard_name: str
    allow_template_only_dest: bool

    if src_kind == "template":
        # ----- Step 2a: pick a template file -----
        click.echo("")
        click.echo("Which template would you like to use?")
        for i, p in enumerate(existing_templates, start=1):
            click.echo(f"  {i} = {p.name}")
        tidx = click.prompt(
            "Choice",
            type=click.IntRange(1, len(existing_templates)),
            show_choices=False,
        )
        template_path = existing_templates[tidx - 1]
        template_text = template_path.read_text()
        src_dashboard_name = template_path.stem
        allow_template_only_dest = False
        click.echo(f"Selected template: {template_path}", err=True)
    else:
        # ----- Step 2b: fetch from Metabase, then save to templates_dir -----
        src_env = src_kind  # "staging" or "prod"
        src_label = ENV_LABELS[src_env]
        src_session, src_url = _connect_env(src_env)

        click.echo(f"Loading dashboards from {src_label} ({src_url})...", err=True)
        dashboards = list_dashboards(src_session, src_url)
        if not dashboards:
            raise click.ClickException(f"No dashboards found on {src_label}.")

        click.echo("")
        click.echo("Which dashboard would you like to copy?")
        for i, d in enumerate(dashboards, start=1):
            click.echo(f"  {i} = {d['name']} (id: {d['id']})")
        dash_idx = click.prompt(
            "Choice",
            type=click.IntRange(1, len(dashboards)),
            show_choices=False,
        )
        src_dashboard = dashboards[dash_idx - 1]
        src_dashboard_id = src_dashboard["id"]
        src_dashboard_name = src_dashboard["name"]
        click.echo(
            f"Selected dashboard: {src_dashboard_name} (id: {src_dashboard_id})",
            err=True,
        )

        # Optional: collect agency-style substitutions before exporting.
        # Done here -- after picking the dashboard but before exporting --
        # because the user knows which dashboard they're parameterizing
        # but jinjaify needs the literal->varname pairs in hand to weave
        # placeholders through the YAML.
        parsed_subs = _prompt_for_substitutions()

        # Build template from the live dashboard.  Routed through the
        # shared helper so we pick up source-card discovery / supporting_cards
        # embedding -- the wizard used to skip those and emit half-baked
        # templates that 500'd at apply time.
        try:
            template_text, placeholders_count = export_dashboard_to_template_text(
                src_session,
                src_url,
                src_dashboard_id,
                substitutions=parsed_subs or None,
                resolve_embedded=_confirm_embedded_substitution,
            )
        except TemplateError as exc:
            raise click.ClickException(str(exc))

        # Always save to templates/<id>-<slug>-<timestamp>.yml -- no prompt,
        # since the default is the right answer for ~every case and an
        # unanswered prompt reads as a hang.  The id prefix keeps templates
        # listing in a stable order; the slug suffix makes them
        # recognizable at a glance ('304-ccjpa-reconciliation-...' vs
        # 'dashboard_304'); the timestamp distinguishes re-exports of the
        # same dashboard so they coexist on disk for audit/comparison
        # rather than silently clobbering each other.  Local time
        # (YYYYMMDD-HHMMSS) is unambiguous when files are listed alongside
        # filesystem mtimes -- UTC would be safer cross-tz but harder to
        # eyeball.  If the user wants a different name they can rename
        # after, or use the non-interactive `dashboard-to-template`
        # command with --template-file.
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
        out_path = (
            templates_dir
            / f"{src_dashboard_id}-{_slugify(src_dashboard_name)}-{timestamp}.yml"
        )
        if out_path.exists():
            click.confirm(
                f"{out_path} already exists; overwrite?",
                default=False,
                abort=True,
            )
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(template_text)
        click.echo(f"Wrote template ({placeholders_count} expressions) -> {out_path}")
        allow_template_only_dest = True

    # ----- Step 3: destination -----
    # "Template only" only makes sense when we just fetched from Metabase
    # (i.e. the export step above did real work).  When the source was an
    # existing template, drop that option -- the user must apply somewhere.
    click.echo("")
    click.echo("Where would you like to copy it to?")
    dst_options: list[tuple[str, str]] = []
    if allow_template_only_dest:
        click.echo("  0 = Template only (stop here; template already saved)")
        dst_options.append(("template_only", "0"))
    click.echo("  1 = Metabase Staging")
    dst_options.append(("staging", "1"))
    click.echo("  2 = Metabase Prod")
    dst_options.append(("prod", "2"))

    dst_choice = click.prompt(
        "Choice",
        type=click.Choice([num for _, num in dst_options]),
        show_choices=False,
    )
    dst_kind = next(kind for kind, num in dst_options if num == dst_choice)
    if dst_kind == "template_only":
        return

    # Guard rail: writes to Prod create real cards + a real dashboard, so
    # require an explicit y/N before doing anything (auth, prompts, etc.).
    # Staging is intentionally not gated -- it's the day-to-day target.
    if dst_kind == "prod":
        click.confirm(
            f"\nYou chose {ENV_LABELS['prod']} as the destination. "
            "This will create a new dashboard and cards on production.  Continue?",
            default=False,
            abort=True,
        )

    # ----- Step 4: apply to destination -----
    dst_env = dst_kind
    dst_label = ENV_LABELS[dst_env]
    dst_session, dst_url = _connect_env(dst_env)

    # Walk the template's Jinja AST so we only prompt for variables it
    # actually references.  Templates exported with --no-templatize-name
    # won't ask for a name; templates that don't use --substitution won't
    # ask for agency literals; etc.
    template_vars = _detect_template_vars(template_text)
    context: dict[str, Any] = {}

    click.echo("")
    click.echo(f"Template context for {dst_label}:")

    # database_id -- pick from a list rather than typing the int.
    if "database_id" in template_vars:
        click.echo("Loading databases...", err=True)
        databases = list_databases(dst_session, dst_url)
        if not databases:
            raise click.ClickException(
                f"No databases configured on {dst_label}; cannot pick a target."
            )
        click.echo("")
        click.echo("Target database (where the dashboard's queries will run):")
        for i, db in enumerate(databases, start=1):
            click.echo(f"  {i} = {db['name']} (id: {db['id']})")
        didx = click.prompt(
            "Choice",
            type=click.IntRange(1, len(databases)),
            show_choices=False,
        )
        context["database_id"] = databases[didx - 1]["id"]
        template_vars.discard("database_id")

    # collection_id -- pick from a list.  Paths include parent names so
    # nested duplicates (e.g. two "Reports" folders) are distinguishable.
    if "collection_id" in template_vars:
        click.echo("Loading collections...", err=True)
        collections = list_collections(dst_session, dst_url)
        if not collections:
            raise click.ClickException(
                f"No collections found on {dst_label}; cannot pick a target."
            )
        click.echo("")
        click.echo("Target collection (where the new dashboard will live):")
        for i, c in enumerate(collections, start=1):
            click.echo(f"  {i} = {c['path']} (id: {c['id']})")
        cidx = click.prompt(
            "Choice",
            type=click.IntRange(1, len(collections)),
            show_choices=False,
        )
        context["collection_id"] = collections[cidx - 1]["id"]
        template_vars.discard("collection_id")

    # dashboard_name -- only prompt if the template uses it (i.e. exported
    # with --templatize-name).  Default to the source name.
    if "dashboard_name" in template_vars:
        click.echo("")
        context["dashboard_name"] = click.prompt(
            "New dashboard name", default=src_dashboard_name
        )
        template_vars.discard("dashboard_name")

    # Everything else is a user-defined substitution variable from
    # --substitution at export time.  Prompt for each by name.
    if template_vars:
        click.echo("")
        click.echo(
            f"This template uses {len(template_vars)} additional "
            f"substitution variable(s):"
        )
        for var in sorted(template_vars):
            context[var] = click.prompt(f"  {var}")

    def dst_fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(dst_session, dst_url, db_id)

    env = make_jinja_env(dst_fetch_meta)
    spec = render_template_text(template_text, context, env)
    click.echo("")
    click.echo(f"Applying to {dst_label} ({dst_url})...", err=True)
    apply_dashboard(dst_session, dst_url, spec)


if __name__ == "__main__":
    cli()
