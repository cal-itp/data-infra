# `replicate_bucket_data`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG copies the previous day's raw data from production GCS buckets to staging GCS buckets. It is useful for keeping the staging environment up-to-date with production data, and to allow Analysts to run exploratory queries and test changes efficiently.
