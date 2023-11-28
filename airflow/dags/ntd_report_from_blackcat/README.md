# `ntd_report_from_blackcat`

Type: [Now|Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the publishing and storing of data, in the form of NTD report submissions, first pushing API data into  Google Cloud Storage in the bucket `calitp-ntd-report-validation`.  
  
Another DAG (part of the `create_external_tables` existing DAG) reads the GCS data in BigQuery in the Cal-ITP data warehouse. The job will take the most recent file of each report type (which has all submitted reports by Caltrans 5311 subrecipients) and publish it into BigQuery `external` tables, if it is not yet there. This job uses the Cal-ITP existing infrastructure for creating external tables, outlined [here](https://docs.calitp.org/data-infra/architecture/data.html). 

In the event of failure, the job can be rerun without backfilling. 