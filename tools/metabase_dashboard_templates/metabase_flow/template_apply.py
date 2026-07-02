"""TEMPLATE -> DASHBOARD: the apply core.

Renders a Jinja-templated YAML spec against a target Metabase instance and
creates a fresh dashboard (cards, supporting cards, tabs, dashcards) from it.

Raises `TemplateError` (or `DuplicateDashboardError`) and logs progress via
the stdlib `logging` module.  `make_jinja_env` exposes the `get_table_id` /
`get_field_id` helpers used inside templates; `render_template_text` turns
template text + context into a spec dict; `apply_dashboard` writes it.
"""

import json
import logging
from typing import Callable

import jinja2
import requests
import yaml
from metabase_flow.constants import (
    JINJA_BLOCK_END,
    JINJA_BLOCK_START,
    JINJA_COMMENT_END,
    JINJA_COMMENT_START,
    JINJA_VARIABLE_END,
    JINJA_VARIABLE_START,
    POST_DASHBOARD_KEYS,
    STRIP_CARD_KEYS,
    STRIP_DASHBOARD_KEYS,
)
from metabase_flow.errors import DuplicateDashboardError, TemplateError
from metabase_flow.read_metabase import existing_dashboards_with_name
from metabase_flow.template_export import (
    _find_source_card_int_refs,
    _find_source_card_name_refs,
    _resolve_source_card_names_in_place,
    is_virtual_dashcard,
    strip,
)

logger = logging.getLogger(__name__)


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
        # Custom `$`-sigil delimiters so Metabase's own `{{ ... }}` native-SQL
        # parameters pass through untouched instead of being resolved (and
        # failing) as our variables.  See constants.py for the rationale.
        variable_start_string=JINJA_VARIABLE_START,
        variable_end_string=JINJA_VARIABLE_END,
        block_start_string=JINJA_BLOCK_START,
        block_end_string=JINJA_BLOCK_END,
        comment_start_string=JINJA_COMMENT_START,
        comment_end_string=JINJA_COMMENT_END,
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
    """Raise a TemplateError with Metabase's response body if `r` is not 2xx.

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

    raise TemplateError(
        f"Metabase rejected request: {action}\n"
        f"  HTTP {r.status_code} {r.reason}\n"
        f"{payload_hint}"
        f"  Response body:\n{body_pretty}"
    )


def apply_dashboard(
    session: requests.Session,
    base_url: str,
    spec: dict,
    *,
    force: bool = False,
) -> dict:
    """Create a new dashboard from a fully-rendered template spec.

    Always creates fresh -- in-place update of an existing dashboard was
    removed because the destructive PUT pattern (full dashcards replace,
    plus orphan cards left in the collection) made it too easy to clobber
    a deployed agency dashboard.  Re-apply the template against a fresh
    collection if you need a do-over.

    Raises DuplicateDashboardError if a non-archived dashboard with the same
    name already exists in the target collection, unless `force=True`.
    """
    spec = strip(spec, STRIP_DASHBOARD_KEYS)
    supporting_cards = spec.pop("supporting_cards", None) or []
    dashcards = spec.pop("dashcards", []) or []
    source_tabs = spec.pop("tabs", None) or []

    # Pre-flight: if a non-archived dashboard with this name already exists
    # in the target collection, refuse unless force=True.  Metabase allows
    # duplicate names, so a second apply would silently create a "MyDash
    # (2)"-style sibling -- which is almost never what the user wants.
    # Runs BEFORE any cards are POSTed so a refusal leaves no orphan cards.
    target_name = spec.get("name")
    target_collection_id = spec.get("collection_id")
    if isinstance(target_name, str) and isinstance(target_collection_id, int):
        duplicates = existing_dashboards_with_name(
            session, base_url, target_name, target_collection_id
        )
        if duplicates and not force:
            existing_summary = ", ".join(f"id {d.get('id')}" for d in duplicates)
            raise DuplicateDashboardError(
                f"A dashboard named {target_name!r} already exists in the "
                f"target collection ({existing_summary}).  Creating another "
                "would make a second dashboard with the same name (Metabase "
                "permits duplicates).  Pass force=True to proceed."
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
        logger.info("Creating %s supporting card(s)...", len(supporting_cards))
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
                raise TemplateError(
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
                logger.info("created supporting card %s: %r", c["id"], c["name"])
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
        raise TemplateError(
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
                raise TemplateError(
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
        logger.info("created card %s: %r", c["id"], c["name"])

    # Step 3: POST dashboard shell.
    post_body = {
        k: spec[k] for k in POST_DASHBOARD_KEYS if k in spec and spec[k] is not None
    }
    if "name" not in post_body:
        raise TemplateError("template is missing a top-level `name`")
    r = session.post(f"{base_url}/api/dashboard/", json=post_body)
    _check_metabase_response(r, action="POST /api/dashboard/", payload=post_body)
    dashboard = r.json()
    dashboard_id = dashboard["id"]
    logger.info("created dashboard %s: %r", dashboard_id, dashboard["name"])

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
    logger.info("attached %s dashcards", len(dashcards_put))
    logger.info("View: %s/dashboard/%s", base_url, dashboard_id)
    return final
