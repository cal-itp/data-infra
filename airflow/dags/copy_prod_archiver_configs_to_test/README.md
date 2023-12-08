# `copy_prod_archiver_configs_to_test`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG performs a weekly job to copy the latest prod config into the test bucket so the test archiver doesn't get too out of sync.
