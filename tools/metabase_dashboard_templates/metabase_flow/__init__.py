"""metabase_flow: copy Metabase dashboards via Jinja-templated YAML.

The reusable core behind the dashboard-template CLI.  Export a dashboard to a
template (`template_export`), render and apply a template against a target
instance (`template_apply`), read the Metabase API (`read_metabase`), and fetch
secrets (`gcp_secrets`).  No CLI dependency: functions raise the exceptions in
`errors` and log via the stdlib `logging` module.
"""
