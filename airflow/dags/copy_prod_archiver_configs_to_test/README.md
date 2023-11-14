# `copy_prod_archiver_configs_to_test`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG performs a weekly job to copy the latest prod config into the test bucket so the test archiver doesn't get too out of sync.

## Secrets

You may need to change authentication information in [Secret Manager](https://console.cloud.google.com/security/secret-manager); auth keys are loaded from Secret Manager at the start of DAG executions. You may create new versions of existing secrets, or add entirely new secrets. Secrets must be tagged with `gtfs_schedule: true` to be loaded and are referenced by `url_secret_key_name` or `header_secret_key_name` in Airtable's GTFS dataset records.
