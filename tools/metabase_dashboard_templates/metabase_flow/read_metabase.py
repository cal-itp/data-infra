"""Read-only Metabase HTTP access for the dashboard template tool.

Thin wrappers over the Metabase REST API GET endpoints: build an
authenticated session, fetch dashboards / cards / database metadata, and look
up existing dashboards by name (for the apply-time duplicate check).  Every
function takes an explicit `session` + `base_url`, so callers (and tests)
inject the HTTP boundary rather than this module reaching for global state.

This module is deliberately read-only.  The write operations (POST /api/card,
POST/PUT /api/dashboard) still live inline in `apply_dashboard`, paired with
the `_check_metabase_response` error formatter; they move out with that
function in a later refactor.

TODO: consider unifying *all* Metabase API access (reads here + the writes in
apply_dashboard) into a single client module -- ideally a standalone, reusable
package, since other projects need Metabase API access too and would benefit
from sharing one well-tested client rather than re-implementing it.
"""

import requests


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


def fetch_card(session: requests.Session, base_url: str, card_id: int) -> dict:
    """GET /api/card/{id}.  Used by the source-card discovery pass when a
    dashboard's cards build their queries on top of other saved questions."""
    r = session.get(f"{base_url}/api/card/{card_id}")
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


def existing_dashboards_with_name(
    session: requests.Session,
    base_url: str,
    name: str,
    collection_id: int,
) -> list[dict]:
    """List non-archived dashboards in `collection_id` whose name matches
    `name` (case-insensitive).  Empty list = no collision.

    Bounded to one /api/collection/{id}/items request with a large limit;
    if a collection has > 1000 dashboards we cheerfully miss the long tail
    and let the duplicate happen.  Cal-ITP collections are nowhere near
    that scale.
    """
    try:
        r = session.get(
            f"{base_url}/api/collection/{collection_id}/items",
            params={"models": "dashboard", "archived": "false", "limit": 1000},
        )
        r.raise_for_status()
    except requests.HTTPError:
        # If the collection isn't readable for whatever reason (permissions,
        # API drift), don't fail the apply -- just skip the check.  Worst
        # case the user gets the silent-duplicate they were getting before.
        return []
    payload = r.json()
    items = payload.get("data", []) if isinstance(payload, dict) else payload
    name_norm = name.strip().lower()
    return [
        item
        for item in items
        if isinstance(item, dict)
        and item.get("model") == "dashboard"
        and isinstance(item.get("name"), str)
        and item["name"].strip().lower() == name_norm
        and not item.get("archived")
    ]
