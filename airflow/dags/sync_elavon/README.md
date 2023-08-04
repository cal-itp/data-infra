# `sync_elavon`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG orchestrates the syncing of raw Elavon data. It is part one of the two-part Elavon data pipeline - the second part is the parse_elavon DAG.

elavon_to_gcs_raw.py is a very simple script that mirrors the entire contents of the `data` subfolder in Elavon's provided SFTP server whenver the DAG is run, partitioned by the timestamp at the time of the run. The SFTP server is administered by Elavon, outside the direct control of our ecosystem.

This DAG is context-insensitive (a "now" type DAG), since the source files are not partitioned in any way and prior context can't be accurately reconstructed from the source files in the SFTP server. It will always load the world as it exists at runtime.
