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
    and create (or update) a Metabase dashboard from the result.

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
      --metabase-api-key "$MB_API_KEY" \
      --dashboard-id 9 \
      --template-file dashboard_9.yml

  # Apply that template against DB connection 3, collection 22
  python tools/metabase_dashboard_templates/cli.py template-to-dashboard \
      --metabase-url https://metabase-staging.dds.dot.ca.gov \
      --metabase-api-key "$MB_API_KEY" \
      --template-file dashboard_9.yml \
      --template-context '{"database_id": 3, "collection_id": 22}'

  # Same, but update an existing dashboard instead of creating a new one
  python tools/metabase_dashboard_templates/cli.py template-to-dashboard \
      ... --template-context '{"database_id": 3, "collection_id": 22}' \
      --dashboard-id 42

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
from typing import Any, Callable

import click
import jinja2
import requests
import yaml

# ---------------------------------------------------------------------------
# Strip-key sets
#
# Empirically derived from the Metabase OpenAPI spec (v0.58) plus inspection
# of real GET payloads.  A field is "STRIP" if it is server-generated and
# either ignored or rejected on write.
# ---------------------------------------------------------------------------

STRIP_CARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "last_used_at",
    "view_count",
    "query_average_duration",
    "creator_id",
    "made_public_by_id",
    "public_uuid",
    "dashboard_id",
    "can_write",
    "card_schema",
    "metabase_version",
    "dependency_analysis_version",
    "archived_directly",
    "download_perms",
    "initially_published_at",
    "cache_invalidated_at",
    "moderation_reviews",
    "legacy_query",
    "is_remote_synced",
    "source_card_id",
    "document_id",
    # Stripped because Metabase recomputes it from dataset_query, and the
    # source-DB-specific table_id/field_id values inside it are noise.
    "result_metadata",
}

STRIP_DASHCARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "dashboard_id",
    "collection_authority_level",
    "action_id",
    # card_id is derived at apply time (each new card gets a fresh id);
    # virtual dashcards continue to be detected by visualization_settings.virtual_card.
    "card_id",
}

STRIP_DASHBOARD_KEYS = {
    "id",
    "entity_id",
    "created_at",
    "updated_at",
    "last_viewed_at",
    "last_used_param_values",
    "view_count",
    "creator_id",
    "made_public_by_id",
    "public_uuid",
    "can_write",
    "can_delete",
    "can_restore",
    "archived_directly",
    "param_fields",
    "last-edit-info",
    "collection",
    "collection_authority_level",
    "moderation_reviews",
    "dependency_analysis_version",
    "initially_published_at",
    "is_remote_synced",
}

# Subset of dashboard top-level keys that POST /api/dashboard/ accepts.
# Anything else gets attached via the follow-up PUT /api/dashboard/{id}.
POST_DASHBOARD_KEYS = {
    "name",
    "description",
    "collection_id",
    "collection_position",
    "parameters",
    "cache_ttl",
}


# ---------------------------------------------------------------------------
# Metabase HTTP helpers
# ---------------------------------------------------------------------------


def make_session(api_key: str) -> requests.Session:
    s = requests.Session()
    s.headers.update({"X-API-Key": api_key})
    return s


def fetch_dashboard(
    session: requests.Session, base_url: str, dashboard_id: int
) -> dict:
    r = session.get(f"{base_url}/api/dashboard/{dashboard_id}")
    r.raise_for_status()
    return r.json()


def fetch_database_metadata(
    session: requests.Session, base_url: str, db_id: int
) -> dict:
    """
    Returns id-name maps in both directions:
      - table_by_id:   table_id -> (schema, table_name)
      - field_by_id:   field_id -> (schema, table_name, column_name)
      - table_to_id:   (schema, table_name) -> table_id
      - field_to_id:   (schema, table_name, column_name) -> field_id
    """
    r = session.get(f"{base_url}/api/database/{db_id}/metadata")
    r.raise_for_status()
    raw = r.json()
    table_by_id, table_to_id = {}, {}
    field_by_id, field_to_id = {}, {}
    for t in raw.get("tables", []):
        key = (t["schema"], t["name"])
        table_by_id[t["id"]] = key
        table_to_id[key] = t["id"]
        for f in t.get("fields", []):
            fkey = (t["schema"], t["name"], f["name"])
            field_by_id[f["id"]] = fkey
            field_to_id[fkey] = f["id"]
    return {
        "table_by_id": table_by_id,
        "field_by_id": field_by_id,
        "table_to_id": table_to_id,
        "field_to_id": field_to_id,
    }


# ---------------------------------------------------------------------------
# Strip / classify
# ---------------------------------------------------------------------------


def strip(d: dict, keys: set) -> dict:
    return {k: v for k, v in d.items() if k not in keys}


def is_virtual_dashcard(dc: dict) -> bool:
    """A virtual dashcard is a text/heading block: card_id is null AND
    visualization_settings carries a virtual_card descriptor."""
    vs = dc.get("visualization_settings") or {}
    return dc.get("card_id") is None and "virtual_card" in vs


def strip_dashboard_for_template(dashboard: dict) -> dict:
    """Recursively remove server-generated keys from a dashboard payload.
    The result is the canonical pre-Jinja shape that dashboard_to_template
    operates on and that template_to_dashboard expects after rendering."""
    cleaned = strip(dashboard, STRIP_DASHBOARD_KEYS)
    new_dashcards = []
    for dc in cleaned.get("dashcards") or []:
        cdc = strip(dc, STRIP_DASHCARD_KEYS)
        card = cdc.get("card")
        if isinstance(card, dict):
            stripped_card = strip(card, STRIP_CARD_KEYS)
            if stripped_card:
                cdc["card"] = stripped_card
            else:
                cdc.pop("card", None)
        new_dashcards.append(cdc)
    cleaned["dashcards"] = new_dashcards
    return cleaned


# ---------------------------------------------------------------------------
# DASHBOARD -> TEMPLATE: Jinja-ify
# ---------------------------------------------------------------------------

PLACEHOLDER_PREFIX = "__JINJAEXPR_"
PLACEHOLDER_SUFFIX = "__"


def _placeholder(idx: int) -> str:
    return f"{PLACEHOLDER_PREFIX}{idx}{PLACEHOLDER_SUFFIX}"


def jinjaify(
    dashboard: dict,
    fetch_metadata: Callable[[int], dict],
) -> tuple[dict, dict[int, str]]:
    """Walk a dashboard, replacing instance-specific ids with placeholder
    strings.  Returns (mutated_dashboard, {placeholder_index: jinja_expr}).

    Replaces:
      database / database_id  -> {{ database_id }}
      collection_id           -> {{ collection_id }}
      table_id / source-table -> {{ get_table_id(database_id, "schema.table") }}
      MBQL field-ref ints     -> {{ get_field_id(database_id, "schema.table", "column") }}

    Raises ClickException if more than one source database OR more than one
    source collection is encountered; this prototype assumes a single
    `database_id` and a single `collection_id` in the template context.
    """
    placeholders: dict[int, str] = {}
    counter = [0]
    seen_source_dbs: set[int] = set()
    seen_source_collections: set[int] = set()

    def alloc(expr: str) -> str:
        idx = counter[0]
        counter[0] += 1
        placeholders[idx] = expr
        return _placeholder(idx)

    metadata_cache: dict[int, dict] = {}

    def meta(db_id: int) -> dict:
        if db_id not in metadata_cache:
            metadata_cache[db_id] = fetch_metadata(db_id)
        return metadata_cache[db_id]

    def resolve_field_ref(ref: list, db_id: int) -> None:
        """Resolve an MBQL `["field", ...]` ref in place by replacing its
        int id slot with a placeholder.  Two forms:
          legacy: ["field", <int id>, <opts>]
          lib:    ["field", <opts>, <int id>]
        Raises if the id is not in the source DB metadata."""
        fields_by_id = meta(db_id)["field_by_id"]
        for pos in (1, 2):
            if pos < len(ref) and isinstance(ref[pos], int):
                field_id = ref[pos]
                key = fields_by_id.get(field_id)
                if key is None:
                    raise click.ClickException(
                        f"field id {field_id} not found in source DB {db_id} metadata"  # noqa: E713
                    )
                s, t, c = key
                ref[pos] = alloc(f'get_field_id(database_id, "{s}.{t}", "{c}")')
                return

    def resolve_viz_field_ref(
        ref: list,
        db_id: int,
        viz_table: tuple[str, str] | None,
        column_name: str | None,
    ) -> None:
        """Like resolve_field_ref, but for refs inside visualization_settings,
        where Metabase tolerates stale ids and matches columns by name at
        render time.  Prefer the live id when it resolves; otherwise fall
        back to the sibling column `name` + enclosing card table.  As a
        last resort leave the int in place (Metabase will name-match)."""
        for pos in (1, 2):
            if pos < len(ref) and isinstance(ref[pos], int):
                stale_id = ref[pos]
                key = meta(db_id)["field_by_id"].get(stale_id)
                if key is not None:
                    s, t, c = key
                elif viz_table is not None and column_name:
                    s, t = viz_table
                    c = column_name
                else:
                    click.echo(
                        f"  warn: viz field id {stale_id} unresolved and no "
                        f"name/table fallback available; leaving as-is",  # noqa: E702
                        err=True,
                    )
                    return
                ref[pos] = alloc(f'get_field_id(database_id, "{s}.{t}", "{c}")')
                return

    def walk(
        node: Any,
        db_id: int | None,
        viz_table: tuple[str, str] | None = None,
    ) -> None:
        if isinstance(node, dict):
            local = db_id
            # First pass: pin down the active db at this level so siblings
            # like `table_id: 14` can resolve before they're processed.
            for k in ("database_id", "database"):
                if isinstance(node.get(k), int):
                    local = node[k]
                    seen_source_dbs.add(local)
                    node[k] = alloc("database_id")
            # Capture this dict's table for descendants (in particular
            # visualization_settings, which uses `name` to refer to columns
            # of this table).  We do this before the second pass so the
            # placeholder swap below doesn't lose the int.
            local_viz_table = viz_table
            for k in ("table_id", "source-table"):
                v = node.get(k)
                if isinstance(v, int) and local is not None:
                    key = meta(local)["table_by_id"].get(v)
                    if key is not None:
                        local_viz_table = key
                    break
            # If we're a viz column entry (a dict with a column `name` and a
            # field ref), resolve the ref via name-with-stale-id-fallback
            # before the generic walk gets to it.  After this, the int slot
            # is a placeholder string and the generic list handler below
            # is a no-op for it.
            if viz_table is not None and isinstance(node.get("name"), str):
                for ref_key in ("fieldRef", "field_ref"):
                    ref = node.get(ref_key)
                    if (
                        isinstance(ref, list)
                        and len(ref) >= 2
                        and ref[0] == "field"
                        and local is not None
                    ):
                        resolve_viz_field_ref(ref, local, viz_table, node["name"])
            # Second pass: process the rest.
            for k, v in list(node.items()):
                if k in ("database_id", "database"):
                    continue
                if k == "collection_id" and isinstance(v, int):
                    seen_source_collections.add(v)
                    node[k] = alloc("collection_id")
                    continue
                if (
                    k in ("table_id", "source-table")
                    and isinstance(v, int)
                    and local is not None
                ):
                    key = meta(local)["table_by_id"].get(v)
                    if key is None:
                        raise click.ClickException(
                            f"{k}={v} not found in source DB {local} metadata "  # noqa: E713
                            "(table may have been dropped or renamed)"
                        )
                    schema, table = key
                    node[k] = alloc(f'get_table_id(database_id, "{schema}.{table}")')
                    continue
                # Propagate viz_table only into visualization_settings.
                child_viz_table = (
                    local_viz_table if k == "visualization_settings" else viz_table
                )
                walk(v, local, child_viz_table)
        elif isinstance(node, list):
            if (
                len(node) >= 2
                and node[0] == "field"
                and db_id is not None
                and any(isinstance(node[p], int) for p in (1, 2) if p < len(node))
            ):
                if viz_table is not None:
                    # Inside visualization_settings without a named-column
                    # parent (rare; the `name`-bearing parent dict above
                    # would have already handled it).  Be lenient.
                    resolve_viz_field_ref(node, db_id, viz_table, None)
                else:
                    resolve_field_ref(node, db_id)
            for item in node:
                walk(item, db_id, viz_table)

    walk(dashboard, None)

    if len(seen_source_dbs) > 1:
        raise click.ClickException(
            f"Dashboard spans multiple source databases {sorted(seen_source_dbs)}. "
            "This prototype assumes a single `database_id` in the template context. "
            "Split the dashboard, or extend this script to emit numbered "
            "database_id_1, database_id_2, ... and pass each in --template-context."
        )
    if len(seen_source_collections) > 1:
        raise click.ClickException(
            f"Dashboard spans multiple source collections {sorted(seen_source_collections)}. "
            "This prototype assumes a single `collection_id` in the template context. "
            "Edit the source dashboard so all cards share one collection, or extend "
            "this script to emit numbered collection_id_1, collection_id_2, ..."
        )

    return dashboard, placeholders


def emit_template_yaml(dashboard: dict, placeholders: dict[int, str]) -> str:
    """Dump a placeholder-substituted dashboard to YAML, then swap each
    placeholder (with any quotes PyYAML wrapped it in) for the corresponding
    Jinja2 expression."""
    text = yaml.safe_dump(
        dashboard,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
    )
    for idx, expr in placeholders.items():
        ph = _placeholder(idx)
        replacement = "{{ " + expr + " }}"
        # Order matters: handle quoted forms before bare ones.
        text = text.replace(f"'{ph}'", replacement)
        text = text.replace(f'"{ph}"', replacement)
        text = text.replace(ph, replacement)
    return text


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
) -> dict:
    out = {
        "id": neg_id,
        "row": source_dc["row"],
        "col": source_dc["col"],
        "size_x": source_dc["size_x"],
        "size_y": source_dc["size_y"],
        "parameter_mappings": source_dc.get("parameter_mappings") or [],
        "visualization_settings": source_dc.get("visualization_settings") or {},
        "series": source_dc.get("series") or [],
    }
    if new_card_id is not None:
        out["card_id"] = new_card_id
    return out


def apply_dashboard(
    session: requests.Session,
    base_url: str,
    spec: dict,
    *,
    existing_dashboard_id: int | None,
) -> dict:
    """Create or update a dashboard from a fully-rendered template spec.

    UPDATE semantics: dashcards[] is a full replace (PUT replaces, not
    merges).  Top-level fields present in the spec are overwritten on the
    target; absent fields are left alone.  Cards from previous renders
    are not deleted -- they stay in their collection as orphans.
    """
    spec = strip(spec, STRIP_DASHBOARD_KEYS)
    dashcards = spec.pop("dashcards", []) or []

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
        r.raise_for_status()
        c = r.json()
        created_card_ids.append(c["id"])
        click.echo(f"  created card {c['id']}: {c['name']!r}")

    # Step 3: dashboard shell -- POST (create) or stay-with-existing (update).
    if existing_dashboard_id is None:
        post_body = {
            k: spec[k] for k in POST_DASHBOARD_KEYS if k in spec and spec[k] is not None
        }
        if "name" not in post_body:
            raise click.ClickException("template is missing a top-level `name`")
        r = session.post(f"{base_url}/api/dashboard/", json=post_body)
        r.raise_for_status()
        dashboard = r.json()
        dashboard_id = dashboard["id"]
        click.echo(f"  created dashboard {dashboard_id}: {dashboard['name']!r}")
    else:
        dashboard_id = existing_dashboard_id
        click.echo(f"  updating existing dashboard {dashboard_id}")

    # Step 4: PUT /api/dashboard/{id} with template's top-level fields + dashcards.
    dashcards_put = [
        build_dashcard_for_put(
            src_dc,
            neg_id=-(i + 1),
            new_card_id=created_card_ids[idx] if idx >= 0 else None,
        )
        for i, (src_dc, idx) in enumerate(plan)
    ]
    put_body = dict(spec)  # everything from the template that survived strip
    put_body["dashcards"] = dashcards_put
    r = session.put(f"{base_url}/api/dashboard/{dashboard_id}", json=put_body)
    r.raise_for_status()
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
    required=True,
    envvar="METABASE_URL",
    help="Base URL of the Metabase instance (env: METABASE_URL).",
)
@click.option(
    "--metabase-api-key",
    required=True,
    envvar="METABASE_API_KEY",
    help="Metabase API key (env: METABASE_API_KEY).",
)
@click.pass_context
def cli(ctx: click.Context, metabase_url: str, metabase_api_key: str) -> None:
    """Manage Metabase dashboards as Jinja-templated YAML files."""
    ctx.ensure_object(dict)
    ctx.obj["session"] = make_session(metabase_api_key)
    ctx.obj["base_url"] = metabase_url.rstrip("/")


@cli.command("dashboard-to-template")
@click.option("--dashboard-id", type=int, required=True, help="Source dashboard id.")
@click.option(
    "--template-file",
    type=click.Path(dir_okay=False, writable=True),
    required=True,
    help="Output path.  Use '-' to write to stdout.",
)
@click.pass_context
def cmd_dashboard_to_template(
    ctx: click.Context,
    dashboard_id: int,
    template_file: str,
) -> None:
    """Export a dashboard to a Jinja-templated YAML file."""
    session: requests.Session = ctx.obj["session"]
    base_url: str = ctx.obj["base_url"]

    dashboard = fetch_dashboard(session, base_url, dashboard_id)
    cleaned = strip_dashboard_for_template(dashboard)

    def fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(session, base_url, db_id)

    cleaned, placeholders = jinjaify(cleaned, fetch_meta)
    text = emit_template_yaml(cleaned, placeholders)

    if template_file == "-":
        click.echo(text, nl=False)
    else:
        with open(template_file, "w") as f:
            f.write(text)
        click.echo(
            f"Wrote template ({len(placeholders)} expressions) -> {template_file}"
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
    "--dashboard-id",
    type=int,
    default=None,
    help="If set, update this existing dashboard instead of creating a new one.",
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
    dashboard_id: int | None,
    dry_run: bool,
) -> None:
    """Render a template and create or update a dashboard from it."""
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

    apply_dashboard(
        session,
        base_url,
        spec,
        existing_dashboard_id=dashboard_id,
    )


if __name__ == "__main__":
    cli()
