r"""Sync payments dashboard templates to a set of agencies.

A declarative, non-interactive alternative to the `interactive` wizard in
`cli.py`.  One config file (see `dashboard_config_prod.yml`) names:

  * `template_dashboards` -- the source dashboards to replicate, keyed by a
    stable logical name, each with its id on the *reader* instance and the
    new dashboard name (sans agency prefix).
  * `agencies` -- the places each dashboard is copied to: a target
    `collection_id` and `database_id`, a `name_prefix`, and the list of
    template keys to copy (`dashboards_required`).
  * `environments` -- which `ENVIRONMENTS` keys (environments.py) to use:
    `reader` to export the source dashboards, `writer` to create the copies.
  * `local_storage.path` -- where the exported template files are stored.

The sync runs in two phases:

  1. Export -- read each `template_dashboards` entry from the reader instance
     and write `<local_storage>/<key>.yml`.  (Skippable with --skip-export to
     reuse templates already on disk.)
  2. Apply -- for each agency, render every required template against the
     agency's `database_id` / `collection_id` and a name of
     `name_prefix + new_name_no_prefix`, and create it on the writer instance.

No arbitrary text substitutions are performed: only the three structural
context variables (`database_id`, `collection_id`, `dashboard_name`) are
supplied at apply time.

Usage
-----
    python tools/metabase_dashboard_templates/sync_dashboards.py \
        dashboard_config_prod.yml

    # Re-render against the writer's metadata without creating anything:
    python ... sync_dashboards.py dashboard_config_staging.yml --dry-run

    # Reuse the template files already in local storage:
    python ... sync_dashboards.py dashboard_config_prod.yml --skip-export
"""

from __future__ import annotations

import logging
import sys
from dataclasses import dataclass
from pathlib import Path

import click
import requests
import yaml
from metabase_flow.environments import ENV_LABELS, ENVIRONMENTS
from metabase_flow.errors import DuplicateDashboardError, TemplateError
from metabase_flow.gcp_secrets import SecretAccessError, fetch_secret_from_gcp
from metabase_flow.read_metabase import fetch_database_metadata, make_session
from metabase_flow.template_apply import (
    apply_dashboard,
    make_jinja_env,
    render_template_text,
)
from metabase_flow.template_export import export_dashboard_to_template_text

logger = logging.getLogger("sync_dashboards")


# ---------------------------------------------------------------------------
# Config model
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class TemplateDashboard:
    """One entry under `template_dashboards`."""

    key: str
    prod_id: int
    original_name: str
    new_name_no_prefix: str


@dataclass(frozen=True)
class Agency:
    """One entry under `agencies`."""

    key: str
    name_prefix: str
    collection_id: int
    database_id: int
    dashboards_required: list[str]


@dataclass(frozen=True)
class SyncConfig:
    template_dashboards: dict[str, TemplateDashboard]
    agencies: dict[str, Agency]
    reader_env: str
    writer_env: str
    storage_dir: Path

    def template_path(self, key: str) -> Path:
        return self.storage_dir / f"{key}.yml"


def load_config(config_path: Path) -> SyncConfig:
    """Parse and validate the sync config.

    `local_storage.path` is resolved relative to the config file's directory,
    so the sync behaves the same regardless of the working directory it's run
    from.  Raises click.ClickException with an actionable message on any
    structural problem (missing keys, unknown env names, an agency that
    requires a template that isn't defined).
    """
    try:
        raw = yaml.safe_load(config_path.read_text())
    except yaml.YAMLError as exc:
        raise click.ClickException(f"{config_path} is not valid YAML: {exc}")
    if not isinstance(raw, dict):
        raise click.ClickException(f"{config_path} must be a YAML mapping.")

    def require(mapping: dict, key: str, where: str):
        if key not in mapping or mapping[key] is None:
            raise click.ClickException(f"{where} is missing required key {key!r}.")
        return mapping[key]

    # --- template_dashboards ---
    raw_templates = require(raw, "template_dashboards", str(config_path))
    if not isinstance(raw_templates, dict):
        raise click.ClickException("`template_dashboards` must be a mapping.")
    templates: dict[str, TemplateDashboard] = {}
    for key, entry in raw_templates.items():
        if not isinstance(entry, dict):
            raise click.ClickException(f"template_dashboards.{key} must be a mapping.")
        # Allow placeholder entries (e.g. a not-yet-wired reconciliation
        # dashboard) to sit in the file with null fields; skip them rather
        # than fail.  An agency that *requires* such a key is caught below.
        if entry.get("template_dashboard_prod_id") is None:
            logger.info("Skipping template %r: no template_dashboard_prod_id set.", key)
            continue
        templates[key] = TemplateDashboard(
            key=key,
            prod_id=int(entry["template_dashboard_prod_id"]),
            original_name=str(entry.get("template_dashboard_original_name") or ""),
            new_name_no_prefix=str(
                require(
                    entry,
                    "template_dashboard_new_name_no_prefix",
                    f"template_dashboards.{key}",
                )
            ),
        )
    if not templates:
        raise click.ClickException(
            "No usable entries in `template_dashboards` "
            "(every entry is missing template_dashboard_prod_id)."
        )

    # --- agencies ---
    raw_agencies = require(raw, "agencies", str(config_path))
    if not isinstance(raw_agencies, dict):
        raise click.ClickException("`agencies` must be a mapping.")
    agencies: dict[str, Agency] = {}
    for key, entry in raw_agencies.items():
        if not isinstance(entry, dict):
            raise click.ClickException(f"agencies.{key} must be a mapping.")
        where = f"agencies.{key}"
        required = entry.get("dashboards_required") or []
        if not isinstance(required, list) or not required:
            raise click.ClickException(
                f"{where}.dashboards_required must be a non-empty list."
            )
        unknown = [d for d in required if d not in templates]
        if unknown:
            raise click.ClickException(
                f"{where}.dashboards_required references template(s) "
                f"{unknown!r} that are not defined (or have no prod id) "
                "under `template_dashboards`."
            )
        agencies[key] = Agency(
            key=key,
            name_prefix=str(entry.get("name_prefix") or ""),
            collection_id=int(require(entry, "collection_id", where)),
            database_id=int(require(entry, "database_id", where)),
            dashboards_required=list(required),
        )
    if not agencies:
        raise click.ClickException("`agencies` is empty; nothing to sync.")

    # --- environments ---
    raw_envs = require(raw, "environments", str(config_path))
    reader_env = str(require(raw_envs, "reader", "environments"))
    writer_env = str(require(raw_envs, "writer", "environments"))
    for role, env_name in (("reader", reader_env), ("writer", writer_env)):
        if env_name not in ENVIRONMENTS:
            raise click.ClickException(
                f"environments.{role} = {env_name!r} is not defined in "
                f"environments.py (known: {sorted(ENVIRONMENTS)})."
            )

    # --- local_storage ---
    raw_storage = require(raw, "local_storage", str(config_path))
    storage_path = str(require(raw_storage, "path", "local_storage"))
    storage_dir = (config_path.resolve().parent / storage_path).resolve()

    return SyncConfig(
        template_dashboards=templates,
        agencies=agencies,
        reader_env=reader_env,
        writer_env=writer_env,
        storage_dir=storage_dir,
    )


# ---------------------------------------------------------------------------
# Metabase connection
# ---------------------------------------------------------------------------


def connect_env(env_name: str) -> tuple[requests.Session, str]:
    """Build an authenticated session for an `ENVIRONMENTS` key.

    Fetches the API key from GCP Secret Manager via Application Default
    Credentials, mirroring the wizard's `_connect_env`.
    """
    cfg = ENVIRONMENTS[env_name]
    label = ENV_LABELS.get(env_name, env_name)
    click.echo(f"Fetching API key from GCP for {label}...", err=True)
    try:
        api_key = fetch_secret_from_gcp(str(cfg["gcp_secret"]))
    except SecretAccessError as exc:
        raise click.ClickException(str(exc))
    return make_session(api_key), str(cfg["url"]).rstrip("/")


# ---------------------------------------------------------------------------
# Phases
# ---------------------------------------------------------------------------


def export_templates(
    config: SyncConfig,
    session: requests.Session,
    base_url: str,
) -> list[str]:
    """Export every template dashboard from the reader to local storage.

    Returns a list of human-readable failure messages (empty on full
    success).  One bad dashboard doesn't abort the others -- failures are
    collected and reported at the end so a single broken export still lets
    the rest sync.
    """
    config.storage_dir.mkdir(parents=True, exist_ok=True)
    failures: list[str] = []
    for key, tmpl in config.template_dashboards.items():
        dest = config.template_path(key)
        click.echo(f"Exporting {key} (id {tmpl.prod_id}) -> {dest.name}", err=True)
        try:
            # The dashboard name is templatized so each agency gets its
            # prefix; no other text is parameterized.
            text, n = export_dashboard_to_template_text(
                session,
                base_url,
                tmpl.prod_id,
                templatize_name=True,
            )
        except (TemplateError, requests.HTTPError) as exc:
            failures.append(f"export {key} (id {tmpl.prod_id}): {exc}")
            click.echo(f"  FAILED: {exc}", err=True)
            continue
        dest.write_text(text)
        click.echo(f"  wrote {n} expression(s) -> {dest}", err=True)
    return failures


def apply_to_agencies(
    config: SyncConfig,
    session: requests.Session,
    base_url: str,
    *,
    dry_run: bool,
    force: bool,
) -> list[str]:
    """Render and create every required dashboard for every agency.

    The Jinja env's `get_table_id` / `get_field_id` helpers resolve names
    against the *writer*'s database metadata, so rendering doubles as a
    preflight even under --dry-run.  Returns a list of failure messages.
    """

    def fetch_meta(db_id: int) -> dict:
        return fetch_database_metadata(session, base_url, db_id)

    env = make_jinja_env(fetch_meta)
    failures: list[str] = []

    for agency in config.agencies.values():
        click.echo("", err=True)
        click.echo(
            f"Agency {agency.key}: collection {agency.collection_id}, "
            f"database {agency.database_id}",
            err=True,
        )
        for dash_key in agency.dashboards_required:
            tmpl = config.template_dashboards[dash_key]
            name = f"{agency.name_prefix}{tmpl.new_name_no_prefix}"
            template_path = config.template_path(dash_key)
            if not template_path.exists():
                failures.append(
                    f"{agency.key}/{dash_key}: template file {template_path} "
                    "not found (run without --skip-export, or export first)."
                )
                click.echo(f"  {name}: MISSING template file", err=True)
                continue

            context = {
                "database_id": agency.database_id,
                "collection_id": agency.collection_id,
                "dashboard_name": name,
            }
            try:
                spec = render_template_text(template_path.read_text(), context, env)
            except (TemplateError, KeyError, yaml.YAMLError) as exc:
                failures.append(f"{agency.key}/{dash_key} render: {exc}")
                click.echo(f"  {name}: RENDER FAILED: {exc}", err=True)
                continue

            if dry_run:
                n_cards = len(spec.get("dashcards") or [])
                click.echo(f"  would create {name!r} ({n_cards} dashcard(s))", err=True)
                continue

            try:
                apply_dashboard(session, base_url, spec, force=force)
                click.echo(f"  created {name!r}", err=True)
            except DuplicateDashboardError:
                # Idempotent sync: an existing dashboard with this name is
                # treated as already-synced, not an error.  Use --force to
                # create a duplicate anyway.
                click.echo(
                    f"  {name!r} already exists in collection "
                    f"{agency.collection_id}; skipping (use --force to dup).",
                    err=True,
                )
            except (TemplateError, requests.HTTPError) as exc:
                failures.append(f"{agency.key}/{dash_key} apply: {exc}")
                click.echo(f"  {name}: APPLY FAILED: {exc}", err=True)
    return failures


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


@click.command(context_settings={"help_option_names": ["-h", "--help"]})
@click.argument(
    "config_path",
    metavar="CONFIG",
    type=click.Path(exists=True, dir_okay=False, path_type=Path),
)
@click.option(
    "--dry-run",
    is_flag=True,
    help="Export and render against the writer's metadata, but don't create "
    "any dashboards.  Doubles as a preflight: surfaces missing tables/fields.",
)
@click.option(
    "--skip-export",
    is_flag=True,
    help="Reuse the template files already in local storage instead of "
    "re-exporting them from the reader instance.",
)
@click.option(
    "--force",
    is_flag=True,
    help="Create a dashboard even if one with the same name already exists "
    "in the target collection (default skips it as already-synced).",
)
@click.option(
    "--yes",
    "-y",
    is_flag=True,
    help="Skip the confirmation prompt before writing to a production "
    "writer instance.",
)
def sync(
    config_path: Path,
    dry_run: bool,
    skip_export: bool,
    force: bool,
    yes: bool,
) -> None:
    """Sync the dashboards described by CONFIG to their agencies."""
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stderr)
    config = load_config(config_path)

    click.echo(
        f"Reader: {ENV_LABELS.get(config.reader_env, config.reader_env)}  |  "
        f"Writer: {ENV_LABELS.get(config.writer_env, config.writer_env)}",
        err=True,
    )
    click.echo(f"Local storage: {config.storage_dir}", err=True)

    failures: list[str] = []

    # --- Phase 1: export ---
    if skip_export:
        click.echo("Skipping export; using templates already on disk.", err=True)
    else:
        reader_session, reader_url = connect_env(config.reader_env)
        failures += export_templates(config, reader_session, reader_url)

    # --- Phase 2: apply ---
    # Gate writes to a production writer behind an explicit confirmation,
    # mirroring the wizard's guard.  Skipped for --dry-run (no writes) and
    # when -y is passed.
    writer_is_prod = bool(ENVIRONMENTS[config.writer_env].get("is_production"))
    if not dry_run and writer_is_prod and not yes:
        n_dashboards = sum(len(a.dashboards_required) for a in config.agencies.values())
        click.confirm(
            f"\nThis will create up to {n_dashboards} dashboard(s) on "
            f"{ENV_LABELS.get(config.writer_env, config.writer_env)} "
            "(production).  Continue?",
            default=False,
            abort=True,
        )

    writer_session, writer_url = connect_env(config.writer_env)
    failures += apply_to_agencies(
        config,
        writer_session,
        writer_url,
        dry_run=dry_run,
        force=force,
    )

    # --- Summary ---
    click.echo("", err=True)
    if failures:
        click.echo(f"Sync finished with {len(failures)} failure(s):", err=True)
        for f in failures:
            click.echo(f"  - {f}", err=True)
        raise SystemExit(1)
    click.echo("Sync complete.", err=True)


if __name__ == "__main__":
    sync()
