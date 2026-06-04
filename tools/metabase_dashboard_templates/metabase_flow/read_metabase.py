"""Read-only Metabase HTTP access for the dashboard template tool.

Thin wrappers over the Metabase REST API GET endpoints: build an
authenticated session, fetch dashboards / cards / database metadata, and list
databases, collections, and dashboards for the interactive picker.  Every
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


def list_databases(session: requests.Session, base_url: str) -> list[dict]:
    """Return target Metabase databases sorted by name.

    Drops the built-in Sample Database (id == 1) by default since it's never
    the right answer for cal-itp work; users can still type the id manually
    if they really want it.
    """
    r = session.get(f"{base_url}/api/database")
    r.raise_for_status()
    items = r.json()
    if isinstance(items, dict):
        items = items.get("data", [])
    items = [
        d
        for d in items
        if isinstance(d, dict)
        and d.get("id") is not None
        and d.get("id") != 1  # skip Metabase's Sample Database
    ]
    items.sort(key=lambda d: (d.get("name") or "").lower())
    return items


def list_collections(session: requests.Session, base_url: str) -> list[dict]:
    """Return non-archived collections with a `path` field built from `location`.

    Metabase's collection list is flat; the tree position is encoded in the
    `location` string like `/123/456/`.  We resolve those ids to names so the
    picker shows e.g. "Cal-ITP Reports / Payments" instead of two ambiguous
    rows both labelled "Payments".
    """
    r = session.get(f"{base_url}/api/collection")
    r.raise_for_status()
    items = r.json()
    if isinstance(items, dict):
        items = items.get("data", [])
    items = [
        c
        for c in items
        if isinstance(c, dict)
        and isinstance(c.get("id"), int)  # drop root sentinel (id is None or "root")
        and not c.get("archived")
    ]
    by_id = {c["id"]: c for c in items}

    def path_for(c: dict) -> str:
        loc = c.get("location") or ""
        parent_ids = [int(p) for p in loc.strip("/").split("/") if p.isdigit()]
        parent_names = [by_id[pid]["name"] for pid in parent_ids if pid in by_id]
        return " / ".join(parent_names + [c.get("name") or "?"])

    out = [{"id": c["id"], "path": path_for(c)} for c in items]
    out.sort(key=lambda c: c["path"].lower())
    return out


def list_dashboards(session: requests.Session, base_url: str) -> list[dict]:
    """Return non-archived dashboards sorted by name (case-insensitive).

    Uses GET /api/search (models=dashboard) rather than the deprecated
    GET /api/dashboard/.  Search is paginated in newer Metabase versions, so
    we walk offsets until a short page comes back; older versions return the
    whole set in one page and exit on the first iteration.  Like the old
    endpoint, this only returns dashboards the API key's user can read -- a
    non-admin key sees only the collections its group was granted View on.
    """
    items: list[dict] = []
    limit, offset = 200, 0
    while True:
        r = session.get(
            f"{base_url}/api/search",
            params={
                "models": "dashboard",
                "archived": "false",
                "limit": limit,
                "offset": offset,
            },
        )
        r.raise_for_status()
        payload = r.json()
        # Search always wraps results: {"data": [...], "total": N, ...}.
        page = payload.get("data", []) if isinstance(payload, dict) else payload
        items.extend(
            d
            for d in page
            if isinstance(d, dict)
            and d.get("model") == "dashboard"
            and not d.get("archived")
        )
        if len(page) < limit:
            break
        offset += limit
    items.sort(key=lambda d: (d.get("name") or "").lower())
    return items


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
