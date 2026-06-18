"""DASHBOARD -> TEMPLATE: the export core.

Strips a fetched dashboard, discovers and embeds supporting cards, replaces
instance-specific ids with Jinja expressions, and emits Jinja-templated YAML.

Raises `TemplateError` and logs progress/warnings via the stdlib `logging`
module.
"""

import logging
from typing import Any, Callable

import requests
import yaml
from metabase_flow.constants import (
    JINJA_VARIABLE_END,
    JINJA_VARIABLE_START,
    STRIP_CARD_KEYS,
    STRIP_DASHBOARD_KEYS,
    STRIP_DASHCARD_KEYS,
)
from metabase_flow.errors import TemplateError
from metabase_flow.read_metabase import (
    fetch_card,
    fetch_dashboard,
    fetch_database_metadata,
)

logger = logging.getLogger(__name__)


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

PLACEHOLDER_PREFIX_INT = "__JINJAEXPR_"
PLACEHOLDER_PREFIX_STR = "__JINJASTR_"
PLACEHOLDER_SUFFIX = "__"

# Kept for callers that import the old name -- still points at the int form.
PLACEHOLDER_PREFIX = PLACEHOLDER_PREFIX_INT


def _placeholder(idx: int) -> str:
    """Int-valued placeholder.  After emit_template_yaml's quote-stripping,
    the rendered Jinja produces a bare integer literal, e.g.
        database: ${ database_id }  ->  database: 3
    so YAML parses it as int 3, not the string "3"."""
    return f"{PLACEHOLDER_PREFIX_INT}{idx}{PLACEHOLDER_SUFFIX}"


def _placeholder_str(idx: int) -> str:
    """String-valued placeholder.  After emit_template_yaml's substitution
    the rendered output is `${ var | tojson }`, which Jinja outputs as a
    JSON-encoded string -- complete with surrounding quotes and escaping
    for special YAML characters (#, :, leading dash, etc.).  Without this,
    a user value like '(CCJPA) Clone #2' would have the `#2` parsed away
    as a YAML comment."""
    return f"{PLACEHOLDER_PREFIX_STR}{idx}{PLACEHOLDER_SUFFIX}"


# ---------------------------------------------------------------------------
# Source-card resolution
#
# Metabase cards can build their queries on top of other saved questions via
# `source-card: <int>` (modern MBQL) or `source-table: "card__<int>"`
# (legacy).  Those int ids are meaningful only on the source instance, so
# applying a template that carries them blows up with an FK violation:
#   "Key (source_card_id)=(4427) is not present in table 'report_card'."
#
# Fix: at export time, recursively fetch every referenced card, embed them
# under a top-level `supporting_cards` key, and rewrite each `source-card:
# <int>` (and `source-table: "card__<int>"`) as `source-card-name: "<card
# name>"`.  Card names are stable across instances and survive YAML.
#
# At apply time we POST the supporting cards first (topologically, since
# they can reference each other), build a name -> new_id map, walk the rest
# of the spec replacing every `source-card-name: "X"` with the live
# `source-card: <new_id>`, and continue as normal.
# ---------------------------------------------------------------------------


def _find_source_card_int_refs(node: Any) -> set[int]:
    """Collect every int that's a reference to another Metabase saved
    question, anywhere under `node`.  Three places these show up:

      MBQL stages:    source-card: <int>
      Legacy MBQL:    source-table: "card__<int>"
      Param filters:  values_source_config.card_id: <int>

    Parent-key tracking distinguishes the third from the lookalike
    `parameter_mappings[].card_id` (which points at the dashcard's own card
    and is rewritten elsewhere, not a supporting-card reference)."""
    found: set[int] = set()
    stack: list[tuple[Any, str | None]] = [(node, None)]
    while stack:
        item, parent_key = stack.pop()
        if isinstance(item, dict):
            for k, v in item.items():
                if k == "source-card" and isinstance(v, int):
                    found.add(v)
                    continue
                if (
                    k == "source-table"
                    and isinstance(v, str)
                    and v.startswith("card__")
                ):
                    suffix = v.removeprefix("card__")
                    if suffix.isdigit():
                        found.add(int(suffix))
                        continue
                if (
                    k == "card_id"
                    and isinstance(v, int)
                    and parent_key == "values_source_config"
                ):
                    found.add(v)
                    continue
                stack.append((v, k))
        elif isinstance(item, list):
            for child in item:
                stack.append((child, parent_key))
    return found


def _find_source_card_name_refs(node: Any) -> set[str]:
    """Collect every supporting-card name referenced anywhere in `node`.
    Apply-side uses this for the topo sort of supporting cards.

    Three sentinel patterns mirror the three int-ref patterns:
      source-card-name: "<name>"                          (MBQL stages)
      source-table: "card_name__<name>"                   (legacy MBQL)
      values_source_config.card_name: "<name>"            (param filters)
    """
    found: set[str] = set()
    stack: list[tuple[Any, str | None]] = [(node, None)]
    while stack:
        item, parent_key = stack.pop()
        if isinstance(item, dict):
            for k, v in item.items():
                if k == "source-card-name" and isinstance(v, str):
                    found.add(v)
                    continue
                if (
                    k == "source-table"
                    and isinstance(v, str)
                    and v.startswith("card_name__")
                ):
                    found.add(v.removeprefix("card_name__"))
                    continue
                if (
                    k == "card_name"
                    and isinstance(v, str)
                    and parent_key == "values_source_config"
                ):
                    found.add(v)
                    continue
                stack.append((v, k))
        elif isinstance(item, list):
            for child in item:
                stack.append((child, parent_key))
    return found


def _resolve_source_card_names_in_place(
    node: Any,
    name_to_id: dict[str, int],
    _parent_key: str | None = None,
) -> None:
    """Walk `node`, rewriting every name-based supporting-card reference into
    a live int id using `name_to_id`.  Mutates in place.

    Reverses the three sentinel patterns emitted by jinjaify:
      source-card-name: "X"               -> source-card: <id>
      source-table: "card_name__X"        -> source-table: "card__<id>"
      values_source_config.card_name: "X" -> values_source_config.card_id: <id>

    Raises TemplateError on an unresolved name -- means the template
    references a supporting card that wasn't created or wasn't embedded.
    """
    if isinstance(node, dict):
        if "source-card-name" in node:
            name = node["source-card-name"]
            if name not in name_to_id:
                raise TemplateError(
                    f"Template references source-card-name {name!r} but no "
                    "supporting card with that name was created.  The template "
                    "is malformed or a supporting card failed to apply."
                )
            del node["source-card-name"]
            node["source-card"] = name_to_id[name]
        if isinstance(node.get("source-table"), str) and node[
            "source-table"
        ].startswith("card_name__"):
            name = node["source-table"].removeprefix("card_name__")
            if name not in name_to_id:
                raise TemplateError(
                    f"Template references source-table card_name__{name!r} "
                    "but no supporting card with that name was created."
                )
            node["source-table"] = f"card__{name_to_id[name]}"
        if _parent_key == "values_source_config" and "card_name" in node:
            name = node["card_name"]
            if name not in name_to_id:
                raise TemplateError(
                    f"Template references values_source_config card_name "
                    f"{name!r} but no supporting card with that name was "
                    "created."
                )
            del node["card_name"]
            node["card_id"] = name_to_id[name]
        for k, v in list(node.items()):
            _resolve_source_card_names_in_place(v, name_to_id, _parent_key=k)
    elif isinstance(node, list):
        for item in node:
            _resolve_source_card_names_in_place(
                item, name_to_id, _parent_key=_parent_key
            )


def _fetch_source_cards_recursive(
    session: requests.Session,
    base_url: str,
    initial_refs: set[int],
) -> dict[int, dict]:
    """BFS over `initial_refs`, fetching every referenced card and any cards
    those cards reference.  Returns {card_id: full_card_dict}.

    Cycle-safe via the `in cards_by_id` check before re-fetching.
    """
    cards_by_id: dict[int, dict] = {}
    queue = list(initial_refs)
    while queue:
        cid = queue.pop()
        if cid in cards_by_id:
            continue
        try:
            card = fetch_card(session, base_url, cid)
        except requests.HTTPError as exc:
            raise TemplateError(
                f"Could not fetch source card {cid}: {exc}.  It may be "
                "archived, deleted, or in a collection you can't read."
            )
        cards_by_id[cid] = card
        for ref_id in _find_source_card_int_refs(card):
            if ref_id not in cards_by_id:
                queue.append(ref_id)
    return cards_by_id


def _build_source_card_id_to_name(cards_by_id: dict[int, dict]) -> dict[int, str]:
    """Build {card_id: card_name}.  Raises if two cards share a name -- the
    name is the only stable handle we have, so collisions must be fixed at
    the source before re-exporting."""
    id_to_name: dict[int, str] = {}
    name_to_id: dict[str, int] = {}
    for cid, card in cards_by_id.items():
        name = card.get("name")
        if not isinstance(name, str) or not name.strip():
            raise TemplateError(
                f"Source card id {cid} has no usable name; cannot embed "
                "as a supporting card."
            )
        if name in name_to_id:
            raise TemplateError(
                f"Two source cards share the name {name!r} "
                f"(ids {name_to_id[name]} and {cid}).  Rename one in "
                "Metabase, then re-export."
            )
        id_to_name[cid] = name
        name_to_id[name] = cid
    return id_to_name


def jinjaify(
    dashboard: dict,
    fetch_metadata: Callable[[int], dict],
    *,
    templatize_name: bool = True,
    source_card_id_to_name: dict[int, str] | None = None,
) -> tuple[dict, dict[int, str]]:
    """Walk a dashboard, replacing instance-specific ids with placeholder
    strings.  Returns (mutated_dashboard, {placeholder_index: jinja_expr}).

    Replaces:
      database / database_id  -> {{ database_id }}
      collection_id           -> {{ collection_id }}
      table_id / source-table -> {{ get_table_id(database_id, "schema.table") }}
      MBQL field-ref ints     -> {{ get_field_id(database_id, "schema.table", "column") }}
      source-card             -> source-card-name: "<card name>"   (literal, not Jinja)
      source-table card__N    -> source-table: "card_name__<card name>"
      param values_source_config.card_id -> .card_name: "<card name>"

    If `templatize_name` is True (default), also replaces the top-level
    dashboard `name` with `{{ dashboard_name }}`.  This is the common case
    for branching a canonical template into a new agency's space; pass
    False for migration-style 1:1 copies.

    `source_card_id_to_name` maps each int source-card id to the saved-question
    name to substitute.  The caller is expected to have prefetched referenced
    cards (via _fetch_source_cards_recursive) and embedded them under
    `dashboard["supporting_cards"]` before calling this.  The walk skips the
    multi-collection check for any collection_ids that appear inside
    `supporting_cards`, since those will be retargeted to the dashboard's
    collection at apply time.

    Raises TemplateError if a referenced table/field id is missing from the
    source DB metadata.  Spanning multiple source databases or collections is
    a warning, not an error: every ref collapses to the single
    `{{ database_id }}` / `{{ collection_id }}` chosen at apply time.
    """
    placeholders: dict[int, str] = {}
    counter = [0]
    seen_source_dbs: set[int] = set()
    seen_source_collections: set[int] = set()

    def alloc(expr: str, *, is_string: bool = False) -> str:
        """Allocate a placeholder.  `is_string=True` for values whose Jinja
        result is a YAML string (dashboard_name); the default is_string=False
        is the int form (database_id, table_id, get_field_id(), etc.).
        Without this distinction a user value like 'My Dashboard #2' would
        have the '#2' eaten as a YAML comment."""
        idx = counter[0]
        counter[0] += 1
        placeholders[idx] = expr
        return _placeholder_str(idx) if is_string else _placeholder(idx)

    # Pre-walk: templatize the top-level dashboard name.  Done before the
    # walk so the placeholder is a string by the time the walk recurses
    # past it (the walk only touches ints, so the placeholder is inert).
    if templatize_name and isinstance(dashboard.get("name"), str):
        dashboard["name"] = alloc("dashboard_name", is_string=True)

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
                    raise TemplateError(
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
                    logger.warning(
                        "viz field id %s unresolved and no name/table "
                        "fallback available; leaving as-is",
                        stale_id,
                    )
                    return
                ref[pos] = alloc(f'get_field_id(database_id, "{s}.{t}", "{c}")')
                return

    def walk(
        node: Any,
        db_id: int | None,
        viz_table: tuple[str, str] | None = None,
        inside_viz: bool = False,
        inside_supporting: bool = False,
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
            # If this dict carries a `card` child (i.e. it's a dashcard) but
            # no own database key, inherit db_id from `card.dataset_query` so
            # siblings of `card` -- notably `parameter_mappings` -- get their
            # field refs substituted too.
            if local is None and isinstance(node.get("card"), dict):
                ds = node["card"].get("dataset_query")
                if isinstance(ds, dict):
                    for k in ("database", "database_id"):
                        if isinstance(ds.get(k), int):
                            local = ds[k]
                            break
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
                    # Source cards may live in a different collection from
                    # the dashboard.  Retarget them to the dashboard's
                    # collection at apply time, but don't count their
                    # source collection toward the multi-collection check.
                    if not inside_supporting:
                        seen_source_collections.add(v)
                    node[k] = alloc("collection_id")
                    continue
                if k == "source-card" and isinstance(v, int) and source_card_id_to_name:
                    name = source_card_id_to_name.get(v)
                    if name is not None:
                        del node[k]
                        node["source-card-name"] = name
                        continue
                    # No mapping -- leave as-is and let apply fail clearly.
                if (
                    k == "source-table"
                    and isinstance(v, str)
                    and v.startswith("card__")
                    and source_card_id_to_name
                ):
                    suffix = v.removeprefix("card__")
                    if suffix.isdigit():
                        ref_id = int(suffix)
                        name = source_card_id_to_name.get(ref_id)
                        if name is not None:
                            node[k] = f"card_name__{name}"
                            continue
                if (
                    k in ("table_id", "source-table")
                    and isinstance(v, int)
                    and local is not None
                ):
                    key = meta(local)["table_by_id"].get(v)
                    if key is None:
                        raise TemplateError(
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
                # inside_viz is sticky once set: any descendant of a
                # visualization_settings block is treated as viz, even
                # without a known viz_table.  Without this, dashcard-level
                # visualization_settings (where viz_table can't be inferred
                # from the dashcard itself) hits the strict path and
                # hard-fails on stale ids that Metabase tolerates at runtime.
                child_inside_viz = inside_viz or k == "visualization_settings"
                # supporting_cards is also sticky -- once we descend into the
                # supporting cards list, every descendant is "inside" so we
                # know to skip the multi-collection check on their fields.
                child_inside_supporting = inside_supporting or k == "supporting_cards"
                walk(
                    v,
                    local,
                    child_viz_table,
                    child_inside_viz,
                    child_inside_supporting,
                )
        elif isinstance(node, list):
            if (
                len(node) >= 2
                and node[0] == "field"
                and db_id is not None
                and any(isinstance(node[p], int) for p in (1, 2) if p < len(node))
            ):
                if inside_viz:
                    # Inside visualization_settings without a named-column
                    # parent (the `name`-bearing parent dict above would
                    # have already handled it when viz_table is known).
                    # Be lenient -- Metabase resolves these by name at
                    # render time and tolerates stale ids.
                    resolve_viz_field_ref(node, db_id, viz_table, None)
                else:
                    resolve_field_ref(node, db_id)
            for item in node:
                walk(item, db_id, viz_table, inside_viz, inside_supporting)

    walk(dashboard, None)

    # Second pass for parameter filters: rewrite
    # `parameters[].values_source_config.card_id: <int>` (Metabase pattern
    # for "this filter's dropdown values come from a saved question") into
    # `values_source_config.card_name: "<name>"`.  Apply-side resolves the
    # name back to the live id after creating supporting cards.  Folded
    # into a post-walk pass to avoid threading another parent-key flag
    # through the recursive walk.
    if source_card_id_to_name:

        def rewrite_param_card_refs(n: Any) -> None:
            if isinstance(n, dict):
                vsc = n.get("values_source_config")
                if isinstance(vsc, dict) and isinstance(vsc.get("card_id"), int):
                    cid = vsc["card_id"]
                    name = source_card_id_to_name.get(cid)
                    if name is not None:
                        del vsc["card_id"]
                        vsc["card_name"] = name
                for v in n.values():
                    rewrite_param_card_refs(v)
            elif isinstance(n, list):
                for item in n:
                    rewrite_param_card_refs(item)

        rewrite_param_card_refs(dashboard)

    if len(seen_source_dbs) > 1:
        # Same logic as the multi-collection case: every `database` ref in
        # the template resolves to the same `{{ database_id }}` placeholder,
        # so all cards land against whichever single target database the
        # user picks at apply time -- even if the source dashboard's cards
        # were spread across several DB connections (e.g. main cards
        # against the warehouse, parameter-value cards against a metadata
        # DB).  Schema/table names were discovered against each source DB's
        # metadata, but the lookup at apply time uses the target's
        # metadata.  If a referenced table doesn't exist on the target,
        # apply will fail clearly in get_table_id / get_field_id.
        logger.warning(
            "source dashboard spans %s databases %s; all queries will be "
            "retargeted to the single target database picked at apply time. "
            "Make sure the target exposes every schema/table the source "
            "cards reference, or apply will fail with a 'table not found' "
            "error.",
            len(seen_source_dbs),
            sorted(seen_source_dbs),
        )
    if len(seen_source_collections) > 1:
        # Note: NOT an error.  All `collection_id` refs in the template
        # resolve to the same `{{ collection_id }}` Jinja placeholder, so
        # every card lands together in whichever target collection the user
        # picks at apply time -- even if the source dashboard's cards were
        # spread across several collections.  This is informational so the
        # user knows what's about to happen.
        logger.warning(
            "source dashboard spans %s collections %s; all cards will "
            "land in the single target collection picked at apply time.",
            len(seen_source_collections),
            sorted(seen_source_collections),
        )

    return dashboard, placeholders


def emit_template_yaml(dashboard: dict, placeholders: dict[int, str]) -> str:
    """Dump a placeholder-substituted dashboard to YAML, then swap each
    placeholder (with any quotes PyYAML wrapped it in) for the corresponding
    Jinja2 expression.

    Int placeholders (`__JINJAEXPR_N__`)  -> `{{ expr }}`  (bare; renders
        to a YAML int literal like `3` or `1234`).
    Str placeholders (`__JINJASTR_N__`)   -> `{{ expr | tojson }}`  (Jinja
        outputs a JSON-encoded string with surrounding quotes and any
        escaping needed, so user values containing `#`, `:`, leading `-`,
        etc. survive YAML re-parse intact).
    """
    text = yaml.safe_dump(
        dashboard,
        sort_keys=False,
        allow_unicode=True,
        default_flow_style=False,
    )
    for idx, expr in placeholders.items():
        # Each idx is unique across both forms (single counter), so at most
        # one of these two placeholder strings appears in the text.
        int_ph = _placeholder(idx)
        if int_ph in text:
            replacement = f"{JINJA_VARIABLE_START} {expr} {JINJA_VARIABLE_END}"
            # Order matters: strip quoted forms first so the bare form is
            # only matched on un-quoted occurrences.
            text = text.replace(f"'{int_ph}'", replacement)
            text = text.replace(f'"{int_ph}"', replacement)
            text = text.replace(int_ph, replacement)
            continue
        str_ph = _placeholder_str(idx)
        if str_ph in text:
            # tojson supplies its own quotes, so strip yaml.safe_dump's
            # quoting around the placeholder same way as the int form.
            replacement = f"{JINJA_VARIABLE_START} {expr} | tojson {JINJA_VARIABLE_END}"
            text = text.replace(f"'{str_ph}'", replacement)
            text = text.replace(f'"{str_ph}"', replacement)
            text = text.replace(str_ph, replacement)
    return text


def export_dashboard_to_template_text(
    session: requests.Session,
    base_url: str,
    dashboard_id: int,
    *,
    templatize_name: bool = True,
) -> tuple[str, int]:
    """Full export pipeline: fetch + strip + discover source cards + jinjaify
    + emit YAML text.  Returns (template_text, placeholder_count).

    Runs source-card discovery before jinjaify so the emitted template embeds
    every referenced saved question under `supporting_cards:`; without that,
    apply blows up with the FK violation we now guard against.
    """
    dashboard = fetch_dashboard(session, base_url, dashboard_id)
    cleaned = strip_dashboard_for_template(dashboard)

    # Recursively fetch any saved questions the dashboard's cards build on
    # top of (`source-card: <int>` / `source-table: "card__<int>"`) and
    # embed them under a `supporting_cards:` top-level key.  jinjaify then
    # rewrites every int ref into a name-based sentinel, and apply creates
    # the supporting cards first and resolves the names back to live ids.
    initial_refs = _find_source_card_int_refs(cleaned)
    id_to_name: dict[int, str] = {}
    if initial_refs:
        logger.info(
            "Found %s source-card reference(s) in the dashboard; "
            "recursively fetching supporting cards...",
            len(initial_refs),
        )
        cards_by_id = _fetch_source_cards_recursive(session, base_url, initial_refs)
        id_to_name = _build_source_card_id_to_name(cards_by_id)
        supporting_cards = [strip(c, STRIP_CARD_KEYS) for c in cards_by_id.values()]
        cleaned["supporting_cards"] = supporting_cards
        logger.info("Embedded %s supporting card(s).", len(supporting_cards))

    def fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(session, base_url, db_id)

    cleaned, placeholders = jinjaify(
        cleaned,
        fetch_meta,
        templatize_name=templatize_name,
        source_card_id_to_name=id_to_name,
    )
    return emit_template_yaml(cleaned, placeholders), len(placeholders)
