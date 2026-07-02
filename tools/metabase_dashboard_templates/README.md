# Metabase Dashboard Templates

A tool for replicating a small set of canonical Metabase dashboards across many
transit agencies. You maintain one source dashboard per logical dashboard in
Metabase; the tool exports each into a Jinja-templated YAML file and re-creates
it for every agency, retargeting the table IDs, field IDs, database connection,
and collection to that agency's space.

## Usage

```bash
# from tools/metabase_dashboard_templates/
uv run sync_dashboards.py CONFIG [OPTIONS]
```

Use `uv run sync_dashboards.py --help` to see other options

## General workflow

Editing a dashboard, or onboarding a new agency, follows the same loop:

1. **If updating dashboards: Make the change in Metabase.** Edit the *canonical* source dashboard on the
   reader instance (add a metric, fix a card, etc.), or create the new agency's
   collection and database connection.
2. **Update the config.** Point `template_dashboards` at the source dashboard
   IDs and/or add the agency under `agencies`. See the schema below.
3. **Dry-run.** `uv run sync_dashboards.py <config>.yml --dry-run` re-exports and
   renders against the writer's metadata without creating anything — this is also
   a preflight that surfaces missing tables/fields.
4. **Sync.** `uv run sync_dashboards.py <config>.yml`.
5. **Commit.** Commit both the config change **and** the regenerated template
   files under `local_storage.path` (e.g. `prod_templates/`). The committed
   templates are the version-controlled record of each dashboard's structure, so
   dashboard changes and new agencies both land in git.

## Config file schema

A config is a YAML mapping with four top-level keys. See
`dashboard_config_staging.yml` for a minimal working example.

```yaml
template_dashboards:                
  <template_key>:                   # idenfitier for the dashboard, also the template filename
    template_dashboard_prod_id: 388 # the dashboard's id, found in the dashboard URL (i.e. the id for the following dashboard is 388 https://metabase.dds.dot.ca.gov/dashboard/388-raba-merchant-service-charge-tracking)
    template_dashboard_new_name_no_prefix: "Contactless Payments Metrics Dashboard"  # required

agencies:                           # where each dashboard is copied to
  <agency_key>:                     # identifier for the agency
    name_prefix: "RABA - "          # prefix for each dashboard name
    collection_id: 492              # target collection id, found in the Metabase url (i.e. the id for the following collection is 492: https://metabase.dds.dot.ca.gov/collection/492-test-raba-copied-dashboards)
    database_id: 16                 # target database connection, found in the Metabase url (i.e. the id for the following database connection is 16: https://metabase.dds.dot.ca.gov/browse/databases/16-payments-mst)
    dashboards_required:            # which template_keys to create for this agency (required, non-empty)
      - littlepay_contactless_metrics_dashboard_no_benefits
      - elavon_merchant_service_charge_dashboard

environments:                       # which environments.py entries to use
  reader: "prod_payments_template_reader"   # export source dashboards from here (required)
  writer: "prod_payments_dashboard_writer"  # create copies here (required)

local_storage:
  path: "prod_templates/"           # where template files are written/read (required)
                                    # resolved relative to the config file's directory
```

Notes:

- A `template_dashboards` entry whose `template_dashboard_prod_id` is `null` is
  skipped (handy for not-yet-wired dashboards). An agency that *requires* a
  skipped or undefined key is a hard error.
- A dashboard is named `name_prefix` + `template_dashboard_new_name_no_prefix`.
- `local_storage.path` is resolved relative to the config file, so the sync
  behaves the same regardless of the working directory it's run from.

## Contributing

### Project layout

```
sync_dashboards.py          CLI entry point: config parsing + the two-phase sync
metabase_flow/
  environments.py           instance URLs + GCP secret resources (edit to add instances)
  gcp_secrets.py            fetch the API key from GCP Secret Manager via ADC
  read_metabase.py          authenticated session + read endpoints (dashboards, cards, metadata)
  template_export.py        DASHBOARD -> TEMPLATE: strip, jinjaify, emit YAML
  template_apply.py         TEMPLATE -> DASHBOARD: render Jinja + create on the target
  constants.py              strip-key sets, Jinja delimiters
  errors.py                 TemplateError / DuplicateDashboardError
tests/                      pytest suite (mirrors metabase_flow/)
```

### Running tests

```bash
uv run pytest
```

Tests are pure unit tests with stubbed metadata lookups — they don't touch a live
Metabase instance or GCP.

### Adding an environment

Add an entry to `ENVIRONMENTS` (and a label in `ENV_LABELS`) in
`metabase_flow/environments.py`, then reference its key from a config's
`environments.reader` / `environments.writer`.
