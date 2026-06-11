"""Metabase instance configuration for the dashboard template tool.

Maps each environment name to its base URL and the GCP Secret Manager
resource that holds its API key.  Edit these if the instances move.

These are intentionally hardcoded rather than read from the environment: the
tool targets a fixed set of organization instances.  A sync config's
`environments.reader` / `environments.writer` keys name the entries here to
use for reading source dashboards and writing the copies.

`ENV_LABELS` supplies a human-readable name for log/prompt output.  Set
`is_production: True` to gate writes to that instance behind an explicit y/N
confirmation in `sync_dashboards.py`.
"""

ENVIRONMENTS: dict[str, dict[str, object]] = {
    "staging_payments_writer": {
        "url": "https://metabase-staging.dds.dot.ca.gov",
        "gcp_secret": (
            "projects/cal-itp-data-infra-staging/secrets/"
            "metabase-dashboard-copy-tool-metabase-staging-api-key/versions/latest"
        ),
        "is_production": False,
    },
    "prod_payments_template_reader": {
        "url": "https://metabase.dds.dot.ca.gov",
        "gcp_secret": (
            "projects/cal-itp-data-infra/secrets/"
            "metabase-dashboard-copy-tool-metabase-prod-api-key/versions/latest"
        ),
        "is_production": True,
    },
    "prod_payments_dashboard_writer": {
        "url": "https://metabase.dds.dot.ca.gov",
        "gcp_secret": (
            "projects/cal-itp-data-infra/secrets/"
            "metabase-dashboard-copy-tool-metabase-prod-writer-api-key/versions/latest"
        ),
        "is_production": True,
    },
}

# Human-readable labels for each environment, used in interactive prompts.
ENV_LABELS: dict[str, str] = {
    "staging_payments_writer": "Metabase Staging - Payments Writer",
    "prod_payments_template_reader": "Metabase Prod - Payments Template Reader",
    "prod_payments_dashboard_writer": "Metabase Prod - Payments Dashboard Writer",
}
