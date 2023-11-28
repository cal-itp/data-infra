# `ntd_report_publish_validation`

Type: [Now|Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the publishing of NTD Report validation checks in the form of Excel files, that it saves into Google Cloud Storage. Checks conducted on submitted NTD report submissions, previously stored into BigQuery with dbt models. They are then converted to Excel files and saves in the Google Cloud Storage bucket `calitp-ntd-report-validation`.  

In the event of failure, the job can be rerun without backfilling. 