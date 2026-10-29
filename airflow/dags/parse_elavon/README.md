# `parse_elavon`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the parsing of Elavon data. Raw data is transferred from Elavon's source SFTP server to GCS using Terraform-managed SFTP infrastructure. Starting with the partitioned, zipped, pipe-separated text files stored in GCS, `elavon_to_gcs_jsonl.py` produces JSONL files to be read into external tables, which then are used by downstream dbt models.

Even though this is a parse job, it handles all of history (since each new timestamped partition this DAG picks up contains the full contents of the source SFTP server) so it is a "now" type DAG.

This implementation is meant to be temporary.  Each zip is read one by one, processes each zip file individually in memory, cleans the columns to be BQ-safe, and saves one .jsonl.gz per source file to
CALITP_BUCKET__ELAVON_PARSED. All output files share the same execution_ts so they land in the same partition.
