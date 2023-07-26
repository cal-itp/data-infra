# `create_external_tables`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the creation of [external tables](https://cloud.google.com/bigquery/docs/external-data-sources), which serve as the interface between our raw / parsed data (stored in Google Cloud Storage) and our data warehouse (BigQuery). Most of our external tables are [hive-partitioned](https://cloud.google.com/bigquery/docs/hive-partitioned-loads-gcs).
