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
import os
import re
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Any, Callable

import click
import jinja2
import jinja2.meta
import requests
import yaml

# ---------------------------------------------------------------------------
# Environment configuration
#
# Maps "staging" and "prod" to the Metabase URL + GCP Secret Manager resource
# holding that instance's API key.  The interactive wizard uses these.  Each
# value is overridable at runtime via env var so deployment-specific names
# don't need a code change:
#   METABASE_STAGING_URL, METABASE_STAGING_GCP_SECRET
#   METABASE_PROD_URL,    METABASE_PROD_GCP_SECRET
# ---------------------------------------------------------------------------

ENVIRONMENTS: dict[str, dict[str, str]] = {
    "staging": {
        "url": os.environ.get(
            "METABASE_STAGING_URL",
            "https://metabase-staging.dds.dot.ca.gov",
        ),
        "gcp_secret": os.environ.get(
            "METABASE_STAGING_GCP_SECRET",
            "projects/cal-itp-data-infra-staging/secrets/"
            "metabase-dashboard-copy-tool-metabase-staging-api-key/versions/latest",
        ),
    },
    "prod": {
        "url": os.environ.get(
            "METABASE_PROD_URL",
            "https://metabase.dds.dot.ca.gov",
        ),
        "gcp_secret": os.environ.get(
            "METABASE_PROD_GCP_SECRET",
            "projects/cal-itp-data-infra/secrets/"
            "metabase-dashboard-copy-tool-metabase-prod-api-key/versions/latest",
        ),
    },
}

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


# ---------------------------------------------------------------------------
# GCP Secret Manager
# ---------------------------------------------------------------------------


def _run_gcloud_adc_login() -> None:
    """Shell out to `gcloud auth application-default login`.

    Used when ADC are missing so the user doesn't have to drop out of the
    wizard to run it themselves.  Inherits stdio so the gcloud browser flow
    works normally (gcloud prints a URL, the user signs in, control returns).
    """
    if shutil.which("gcloud") is None:
        raise click.ClickException(
            "gcloud CLI not found on PATH.  Install the Google Cloud SDK "
            "(https://cloud.google.com/sdk/docs/install) and try again."
        )
    click.echo(
        "Launching `gcloud auth application-default login` "
        "(a browser tab will open)...",
        err=True,
    )
    try:
        subprocess.run(["gcloud", "auth", "application-default", "login"], check=True)
    except subprocess.CalledProcessError as exc:
        raise click.ClickException(
            f"`gcloud auth application-default login` failed "
            f"(exit code {exc.returncode})."
        )
    except KeyboardInterrupt:
        raise click.ClickException("Login cancelled.")


def fetch_secret_from_gcp(secret_resource_name: str) -> str:
    """Fetch a secret payload from GCP Secret Manager via Application Default Credentials.

    `secret_resource_name` must be a fully-qualified resource name:
        projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION
    Use "latest" as VERSION to always get the current active version.

    If ADC is not configured, this transparently runs
    `gcloud auth application-default login` and retries once.  All other
    failures (malformed name, secret missing, permission denied, transport
    errors) raise ClickException with a message that names the secret.
    """
    try:
        from google.api_core import exceptions as gcp_exceptions
        from google.auth import exceptions as auth_exceptions
        from google.cloud import secretmanager
    except ImportError:
        raise click.ClickException(
            "google-cloud-secret-manager is not installed. "
            "Run: pip install google-cloud-secret-manager"
        )

    # Sanity-check the resource name format up front, so a typo gives a
    # clearer error than the server's InvalidArgument.
    parts = secret_resource_name.split("/")
    if (
        len(parts) != 6
        or parts[0] != "projects"
        or parts[2] != "secrets"
        or parts[4] != "versions"
    ):
        raise click.ClickException(
            f"GCP secret resource name is malformed: {secret_resource_name!r}\n"
            "Expected format: "
            "projects/PROJECT_ID/secrets/SECRET_NAME/versions/VERSION "
            "(VERSION may be 'latest')."
        )

    def _build_client():
        return secretmanager.SecretManagerServiceClient()

    try:
        client = _build_client()
    except auth_exceptions.DefaultCredentialsError:
        click.echo(
            "GCP Application Default Credentials are not configured.",
            err=True,
        )
        _run_gcloud_adc_login()
        # Retry once after login completes.  If it still fails here, the
        # exception propagates -- something deeper is wrong (e.g. login
        # succeeded but the credential file is unreadable).
        client = _build_client()

    try:
        response = client.access_secret_version(name=secret_resource_name)
    except auth_exceptions.RefreshError as exc:
        raise click.ClickException(
            f"GCP credentials are expired or invalid "
            f"(needed to fetch {secret_resource_name!r}): {exc}\n"
            "Refresh and retry.  For cal-itp workforce identity:\n"
            "  glogin-calitp-staging   # or glogin-calitp-prod\n"
            "Or run `gcloud auth application-default login` directly."
        )
    except gcp_exceptions.Unauthenticated as exc:
        raise click.ClickException(
            f"GCP rejected your credentials on {secret_resource_name!r}: {exc}\n"
            "Refresh ADC and retry: see your workforce identity login alias "
            "(e.g. glogin-calitp-staging)."
        )
    except gcp_exceptions.NotFound:
        # Reaching this branch is rare -- GCP usually conflates NotFound and
        # PermissionDenied into the latter to avoid leaking secret names.
        raise click.ClickException(
            f"GCP secret not found: {secret_resource_name!r}\n"
            "Verify with:\n"
            f"  gcloud secrets describe {parts[3]} --project={parts[1]}"
        )
    except gcp_exceptions.PermissionDenied as exc:
        raise click.ClickException(
            f"GCP returned 403 on {secret_resource_name!r}: {exc}\n"
            "This means EITHER the secret does not exist OR your account "
            "lacks secretmanager.versions.access.  GCP intentionally collapses "
            "both into the same error.  To distinguish:\n"
            f"  1. Check existence:\n"
            f"       gcloud secrets describe {parts[3]} --project={parts[1]}\n"
            "  2. If `describe` succeeds, you need the role.  Run:\n"
            f"       gcloud secrets add-iam-policy-binding {parts[3]} \\\n"
            f"         --project={parts[1]} \\\n"
            '         --member="user:$(gcloud config get-value account)" \\\n'
            '         --role="roles/secretmanager.secretAccessor"\n'
            "  3. If `describe` returns NOT_FOUND, the secret hasn't been "
            "created yet -- create it (or ask whoever owns the project to)."
        )
    except gcp_exceptions.GoogleAPICallError as exc:
        raise click.ClickException(
            f"GCP error fetching secret {secret_resource_name!r}: {exc}"
        )

    return response.payload.data.decode("utf-8").strip()


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
        database: {{ database_id }}  ->  database: 3
    so YAML parses it as int 3, not the string "3"."""
    return f"{PLACEHOLDER_PREFIX_INT}{idx}{PLACEHOLDER_SUFFIX}"


def _placeholder_str(idx: int) -> str:
    """String-valued placeholder.  After emit_template_yaml's substitution
    the rendered output is `{{ var | tojson }}`, which Jinja outputs as a
    JSON-encoded string -- complete with surrounding quotes and escaping
    for special YAML characters (#, :, leading dash, etc.).  Without this,
    a user value like '(CCJPA) Clone #2' would have the `#2` parsed away
    as a YAML comment."""
    return f"{PLACEHOLDER_PREFIX_STR}{idx}{PLACEHOLDER_SUFFIX}"


def _smart_substitute(
    s: str,
    literal: str,
    placeholder: str,
    decisions: dict[tuple[str, str], bool],
) -> str:
    """Replace `literal` with `placeholder` in `s` -- but for any occurrence
    where `literal` sits inside a larger word (alphanumeric or underscore
    on either side), prompt the user before substituting.

    Without this guard, `LIST` -> `{{ agency_short }}` would happily turn
    `customer_LIST` into `customer_LI{{ agency_short }}`.  We detect that
    case by checking the chars immediately around each occurrence and ask
    once per (literal, surrounding-token) pair; the answer is cached in
    `decisions` so repeated occurrences of the same token across the
    dashboard don't re-prompt.

    Word-boundary occurrences ("MST" in "MST Payments") are substituted
    without prompting -- those are the intentional ones.
    """
    out: list[str] = []
    pos = 0
    n = len(s)
    lit_len = len(literal)
    while pos < n:
        idx = s.find(literal, pos)
        if idx == -1:
            out.append(s[pos:])
            break
        end = idx + lit_len
        left_embedded = idx > 0 and (s[idx - 1].isalnum() or s[idx - 1] == "_")
        right_embedded = end < n and (s[end].isalnum() or s[end] == "_")
        out.append(s[pos:idx])
        if left_embedded or right_embedded:
            # Expand to the full surrounding alnum+underscore token so we
            # can show the user (and key the cache by) the meaningful unit.
            left = idx
            while left > 0 and (s[left - 1].isalnum() or s[left - 1] == "_"):
                left -= 1
            right = end
            while right < n and (s[right].isalnum() or s[right] == "_"):
                right += 1
            surrounding = s[left:right]
            key = (literal, surrounding)
            if key not in decisions:
                rel = idx - left
                end_lit = rel + lit_len
                marked = (
                    surrounding[:rel]
                    + "["
                    + surrounding[rel:end_lit]
                    + "]"
                    + surrounding[end_lit:]
                )
                decisions[key] = click.confirm(
                    f"\n  Substitution {literal!r} would replace text inside "
                    f"the larger token {marked!r}.  Substitute here?",
                    default=False,
                )
            out.append(placeholder if decisions[key] else literal)
        else:
            out.append(placeholder)
        pos = end
    return "".join(out)


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

    Raises ClickException on an unresolved name -- means the template
    references a supporting card that wasn't created or wasn't embedded.
    """
    if isinstance(node, dict):
        if "source-card-name" in node:
            name = node["source-card-name"]
            if name not in name_to_id:
                raise click.ClickException(
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
                raise click.ClickException(
                    f"Template references source-table card_name__{name!r} "
                    "but no supporting card with that name was created."
                )
            node["source-table"] = f"card__{name_to_id[name]}"
        if _parent_key == "values_source_config" and "card_name" in node:
            name = node["card_name"]
            if name not in name_to_id:
                raise click.ClickException(
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
            raise click.ClickException(
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
            raise click.ClickException(
                f"Source card id {cid} has no usable name; cannot embed "
                "as a supporting card."
            )
        if name in name_to_id:
            raise click.ClickException(
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
    substitutions: list[tuple[str, str]] | None = None,
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

    `substitutions` is an optional list of (literal, varname) pairs.  Each
    occurrence of `literal` in any string value (not key) is replaced with
    `{{ varname }}`.  Useful for parameterizing agency-specific text in
    card names, descriptions, and virtual dashcard headings.

    `source_card_id_to_name` maps each int source-card id to the saved-question
    name to substitute.  The caller is expected to have prefetched referenced
    cards (via _fetch_source_cards_recursive) and embedded them under
    `dashboard["supporting_cards"]` before calling this.  The walk skips the
    multi-collection check for any collection_ids that appear inside
    `supporting_cards`, since those will be retargeted to the dashboard's
    collection at apply time.

    Raises ClickException if more than one source database OR more than one
    source collection is encountered; this prototype assumes a single
    `database_id` and a single `collection_id` in the template context.
    """
    placeholders: dict[int, str] = {}
    counter = [0]
    seen_source_dbs: set[int] = set()
    seen_source_collections: set[int] = set()

    def alloc(expr: str, *, is_string: bool = False) -> str:
        """Allocate a placeholder.  `is_string=True` for substitutions whose
        Jinja result is a YAML string (dashboard_name, agency literals);
        the default is_string=False is the int form (database_id, table_id,
        get_field_id(), etc.).  Without this distinction a user value like
        'My Dashboard #2' would have the '#2' eaten as a YAML comment."""
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
        click.echo(
            f"  note: source dashboard spans {len(seen_source_dbs)} "
            f"databases {sorted(seen_source_dbs)}; all queries will be "
            "retargeted to the single target database picked at apply time. "
            "Make sure the target exposes every schema/table the source "
            "cards reference, or apply will fail with a 'table not found' "
            "error.",
            err=True,
        )
    if len(seen_source_collections) > 1:
        # Note: NOT an error.  All `collection_id` refs in the template
        # resolve to the same `{{ collection_id }}` Jinja placeholder, so
        # every card lands together in whichever target collection the user
        # picks at apply time -- even if the source dashboard's cards were
        # spread across several collections.  This is informational so the
        # user knows what's about to happen.
        click.echo(
            f"  note: source dashboard spans {len(seen_source_collections)} "
            f"collections {sorted(seen_source_collections)}; all cards will "
            "land in the single target collection picked at apply time.",
            err=True,
        )

    # Post-walk: apply user-supplied literal->variable substitutions across
    # every string value in the dashboard.  Each substitution allocates one
    # placeholder, reused for every match.  Longer literals are applied
    # first so overlapping prefixes (e.g. "MST" inside "MST Authority")
    # bind to the more-specific match.
    if substitutions:
        sub_phs: list[tuple[str, str]] = []  # (literal, placeholder)
        for literal, varname in substitutions:
            # Substitutions are inline within larger strings (e.g.
            # "MST overview" -> "{{ agency_short }} overview").  Using the
            # int-form bare `{{ var }}` keeps the surrounding YAML text
            # intact; tojson here would inject quotes mid-string and break
            # parse.  Trade-off: substitution values with YAML metachars
            # (`:` / `#` etc.) can break the rendered YAML.  Typical agency
            # short codes are fine; document the limitation if it bites.
            sub_phs.append((literal, alloc(varname)))
        sub_phs.sort(key=lambda lp: -len(lp[0]))

        # Per-export cache: {(literal, surrounding_token): substitute?}.  An
        # embedded occurrence (e.g. "LIST" inside "customer_LIST") triggers
        # a y/N prompt; that decision is stored here so the same token
        # repeated across multiple string values across the dashboard isn't
        # re-prompted dozens of times.
        embedded_decisions: dict[tuple[str, str], bool] = {}

        def replace_in_strings(node: Any) -> None:
            if isinstance(node, dict):
                for k, v in list(node.items()):
                    if isinstance(v, str):
                        for literal, ph in sub_phs:
                            if literal in v:
                                v = _smart_substitute(
                                    v, literal, ph, embedded_decisions
                                )
                        node[k] = v
                    else:
                        replace_in_strings(v)
            elif isinstance(node, list):
                for i, v in enumerate(node):
                    if isinstance(v, str):
                        for literal, ph in sub_phs:
                            if literal in v:
                                v = _smart_substitute(
                                    v, literal, ph, embedded_decisions
                                )
                        node[i] = v
                    else:
                        replace_in_strings(v)

        replace_in_strings(dashboard)

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
            replacement = "{{ " + expr + " }}"
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
            replacement = "{{ " + expr + " | tojson }}"
            text = text.replace(f"'{str_ph}'", replacement)
            text = text.replace(f'"{str_ph}"', replacement)
            text = text.replace(str_ph, replacement)
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


def _existing_dashboards_with_name(
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
        duplicates = _existing_dashboards_with_name(
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
        api_key = fetch_secret_from_gcp(gcp_secret)
    ctx.obj["session"] = make_session(api_key)
    ctx.obj["base_url"] = url.rstrip("/")


def export_dashboard_to_template_text(
    session: requests.Session,
    base_url: str,
    dashboard_id: int,
    *,
    templatize_name: bool = True,
    substitutions: list[tuple[str, str]] | None = None,
) -> tuple[str, int]:
    """Full export pipeline: fetch + strip + discover source cards + jinjaify
    + emit YAML text.  Returns (template_text, placeholder_count).

    Lifted out of `cmd_dashboard_to_template` so the interactive wizard's
    "fetch from Metabase" branch hits the same code path.  Without this,
    the wizard skipped source-card discovery and produced templates that
    blew up at apply with the FK violation we're now guarding against.
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
        click.echo(
            f"Found {len(initial_refs)} source-card reference(s) in the "
            "dashboard; recursively fetching supporting cards...",
            err=True,
        )
        cards_by_id = _fetch_source_cards_recursive(session, base_url, initial_refs)
        id_to_name = _build_source_card_id_to_name(cards_by_id)
        supporting_cards = [strip(c, STRIP_CARD_KEYS) for c in cards_by_id.values()]
        cleaned["supporting_cards"] = supporting_cards
        click.echo(f"Embedded {len(supporting_cards)} supporting card(s).", err=True)

    def fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(session, base_url, db_id)

    cleaned, placeholders = jinjaify(
        cleaned,
        fetch_meta,
        templatize_name=templatize_name,
        substitutions=substitutions,
        source_card_id_to_name=id_to_name,
    )
    return emit_template_yaml(cleaned, placeholders), len(placeholders)


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

    text, placeholder_count = export_dashboard_to_template_text(
        session,
        base_url,
        dashboard_id,
        templatize_name=templatize_name,
        substitutions=parsed_subs,
    )

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


ENV_LABELS: dict[str, str] = {
    "staging": "Metabase Staging",
    "prod": "Metabase Prod",
}

# Directory where exported templates live (and where the wizard looks for
# already-exported ones).  Sits next to this script so the templates ship
# alongside the tool in source control.
TEMPLATES_DIR: Path = Path(__file__).resolve().parent / "templates"


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
    api_key = fetch_secret_from_gcp(cfg["gcp_secret"])
    return make_session(api_key), cfg["url"].rstrip("/")


def _list_databases(session: requests.Session, base_url: str) -> list[dict]:
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


def _list_collections(session: requests.Session, base_url: str) -> list[dict]:
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


def _list_dashboards(session: requests.Session, base_url: str) -> list[dict]:
    """Return non-archived dashboards sorted by name (case-insensitive)."""
    r = session.get(f"{base_url}/api/dashboard/")
    r.raise_for_status()
    items = r.json()
    if not isinstance(items, list):
        # Some Metabase versions wrap the list -- defensive fallback.
        items = items.get("data", []) if isinstance(items, dict) else []
    items = [d for d in items if not d.get("archived")]
    items.sort(key=lambda d: (d.get("name") or "").lower())
    return items


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
    name per environment in ENVIRONMENTS at the top of this file (or via the
    METABASE_{STAGING,PROD}_{URL,GCP_SECRET} env vars).
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
        dashboards = _list_dashboards(src_session, src_url)
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
        template_text, placeholders_count = export_dashboard_to_template_text(
            src_session,
            src_url,
            src_dashboard_id,
            substitutions=parsed_subs or None,
        )

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
        databases = _list_databases(dst_session, dst_url)
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
        collections = _list_collections(dst_session, dst_url)
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
