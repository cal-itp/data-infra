# `parse_elavon`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the parsing of Elavon data, part two in the pipeline whose part 1 is the `sync_elavon` DAG. Starting with the partitioned, zipped, pipe-separated text files that the `sync_elavon` DAG transfered to GCS from Elavon's source SFTP server, elavon_to_gcs_jsonl.py produces JSONL files to be read into external tables, which then are used by downstream dbt models.

Even though this is a parse job, it handles all of history (since each new timestamped partition this DAG picks up contains the full contents of the source SFTP server, mirrored by the `sync_elavon` DAG) so it is a "now" type DAG.
