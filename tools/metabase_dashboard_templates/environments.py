"""Metabase instance configuration for the dashboard template tool.

Maps the "staging" and "prod" environment names used by the interactive
wizard to each instance's base URL and the GCP Secret Manager resource that
holds its API key.  Edit these if the instances move.

These are intentionally hardcoded rather than read from the environment: the
wizard targets a fixed set of organization instances.  Per-invocation
override lives at the CLI layer instead -- the scriptable subcommands accept
--metabase-url / --gcp-secret (env: METABASE_URL / METABASE_GCP_SECRET).
"""

ENVIRONMENTS: dict[str, dict[str, str]] = {
    "staging": {
        "url": "https://metabase-staging.dds.dot.ca.gov",
        "gcp_secret": (
            "projects/cal-itp-data-infra-staging/secrets/"
            "metabase-dashboard-copy-tool-metabase-staging-api-key/versions/latest"
        ),
    },
    "prod": {
        "url": "https://metabase.dds.dot.ca.gov",
        "gcp_secret": (
            "projects/cal-itp-data-infra/secrets/"
            "metabase-dashboard-copy-tool-metabase-prod-api-key/versions/latest"
        ),
    },
}

# Human-readable labels for each environment, used in interactive prompts.
ENV_LABELS: dict[str, str] = {
    "staging": "Metabase Staging",
    "prod": "Metabase Prod",
}
