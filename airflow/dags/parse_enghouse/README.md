# `parse_enghouse`

Type: [Now / Scheduled](https://docs.calitp.org/data-infra/airflow/dags-maintenance.html)

This DAG converts Enghouse semicolon-delimited CSV files from the raw GCS bucket (`cal-itp-data-infra-enghouse-raw`) into gzipped JSONL files written to the parsed bucket (`calitp-enghouse-parsed`), using `agency={agency}/dt={date}/` Hive partition paths. Downstream BigQuery external tables and dbt models read from the parsed bucket.

Each run scans all files in the raw bucket and skips any already present in the parsed bucket, making it safe to re-run. Late or re-delivered files are automatically picked up on the next scheduled run. This scan-all approach was chosen because Enghouse delivery timing is not guaranteed to be consistent relative to the DAG schedule.

Column names are normalised by `BigQueryCleaner` (lowercased, non-word characters replaced with underscores) to insulate downstream models from casing changes in Enghouse source files.

**Re-parsing:** To re-parse a specific file, delete it from `gs://calitp-enghouse-parsed/` and re-trigger the DAG.

**Pipeline order:** `parse_enghouse` → `create_external_tables` → dbt
