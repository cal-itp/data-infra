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
from typing import Any

import click
import jinja2
import jinja2.meta
import requests

# cli.py is the CLI layer and owns all click usage.  The reusable core modules
# (gcp_secrets, read_metabase, and the export/apply logic) stay click-free:
# they raise plain exceptions and log via the stdlib `logging` module so they
# carry no CLI dependency and can be reused by other tools.  This layer catches
# those exceptions and re-raises them as click.ClickException so the CLI prints
# a clean message instead of a traceback.
from metabase_flow.constants import TEMPLATES_DIR
from metabase_flow.environments import ENV_LABELS, ENVIRONMENTS
from metabase_flow.errors import DuplicateDashboardError, TemplateError
from metabase_flow.gcp_secrets import SecretAccessError, fetch_secret_from_gcp
from metabase_flow.read_metabase import (
    fetch_database_metadata,
    list_collections,
    list_dashboards,
    list_databases,
    make_session,
)
from metabase_flow.template_apply import (
    apply_dashboard,
    make_jinja_env,
    render_template_text,
)
from metabase_flow.template_export import export_dashboard_to_template_text

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
@click.option(
    "--force",
    is_flag=True,
    help="Create the dashboard even if one with the same name already exists "
    "in the target collection (Metabase permits duplicates).",
)
@click.pass_context
def cmd_template_to_dashboard(
    ctx: click.Context,
    template_file: str,
    template_context: str,
    dry_run: bool,
    force: bool,
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

    try:
        apply_dashboard(session, base_url, spec, force=force)
    except DuplicateDashboardError as exc:
        raise click.ClickException(f"{exc}\nRe-run with --force to proceed.")
    except TemplateError as exc:
        raise click.ClickException(str(exc))


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
        api_key = fetch_secret_from_gcp(str(cfg["gcp_secret"]))
    except SecretAccessError as exc:
        raise click.ClickException(str(exc))
    return make_session(api_key), str(cfg["url"]).rstrip("/")


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
    for env_name in ENVIRONMENTS:
        src_options.append((env_name, ENV_LABELS.get(env_name, env_name)))

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
    dst_choices: list[tuple[str, str]] = []  # (kind, label) in display order
    if allow_template_only_dest:
        dst_choices.append(
            ("template_only", "Template only (stop here; template already saved)")
        )
    for env_name in ENVIRONMENTS:
        dst_choices.append((env_name, ENV_LABELS.get(env_name, env_name)))
    # Number from 0 when "template only" is present so it stays option 0;
    # otherwise the environments start at 1.
    start = 0 if allow_template_only_dest else 1
    dst_options = [
        (kind, label, str(i))
        for i, (kind, label) in enumerate(dst_choices, start=start)
    ]
    for kind, label, num in dst_options:
        click.echo(f"  {num} = {label}")

    dst_choice = click.prompt(
        "Choice",
        type=click.Choice([num for _, _, num in dst_options]),
        show_choices=False,
    )
    dst_kind = next(kind for kind, _, num in dst_options if num == dst_choice)
    if dst_kind == "template_only":
        return

    # Guard rail: writes to a production instance create real cards + a real
    # dashboard, so require an explicit y/N before doing anything (auth,
    # prompts, etc.).  Non-production instances (e.g. staging) are not gated
    # -- they're the day-to-day target.  Driven by the `is_production` flag
    # in ENVIRONMENTS so new prod-like instances get the guard for free.
    if ENVIRONMENTS.get(dst_kind, {}).get("is_production"):
        click.confirm(
            f"\nYou chose {ENV_LABELS.get(dst_kind, dst_kind)} as the destination. "
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
    try:
        apply_dashboard(dst_session, dst_url, spec)
    except DuplicateDashboardError as exc:
        # Interactive override: confirm, then retry forcing the duplicate.
        click.confirm(f"\n{exc}\n\nCreate it anyway?", default=False, abort=True)
        try:
            apply_dashboard(dst_session, dst_url, spec, force=True)
        except TemplateError as retry_exc:
            raise click.ClickException(str(retry_exc))
    except TemplateError as exc:
        raise click.ClickException(str(exc))


if __name__ == "__main__":
    cli()
