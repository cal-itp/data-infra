"""
Compacts each UTC day of raw GTFS-RT fetches into hourly parquet archive
files, one task per feed type. The work happens in
plugins/scripts/gtfs_rt_compactor.py; see its docstring for the archive
layout and write-once semantics.

Schedule: daily at 03:30 UTC, when the day being compacted ({{ ds }}, the
run's data interval start) has been closed for 3.5 hours — the archiver only
ever writes into the current hour, so that day can no longer change. With
catchup=True and max_active_runs=1, days backfill oldest-first one at a time.

The compactor CLI reads its buckets from environment variables that
Terraform sets on the Composer environment (composer/us/environment.tf);
the bash command passes no bucket arguments. The CLI's --raw-bucket /
--compacted-bucket / --outcomes-bucket flags override them for local or
manual runs:

    CALITP_BUCKET__GTFS_RT_RAW            source of tiny raw objects (read)
    CALITP_BUCKET__GTFS_RT_RAW_COMPACTED  destination archive (write-once)
    CALITP_BUCKET__GTFS_RT_PARSED         per-hour outcome files (rewritten
                                          every run, success or failure)

Tasks draw from rt_compaction_pool, which must exist in the Airflow
environment before enabling the DAG (pools are provisioned by hand, like
rt_parse_pool; see the Makefile pools target for local dev).
"""
import os
from datetime import datetime, timedelta

from dags import email_on_failure, log_failure_to_slack

from airflow import DAG
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="compact_gtfs_rt_raw",
    tags=["gtfs", "gtfs-rt"],
    # Daily at 03:30 UTC, compacting the previous (fully written) UTC day;
    # that's 8:30 PM PDT / 7:30 PM PST the previous evening
    schedule="30 3 * * *",
    # pilot: catchup compacts each day from here forward; the first run
    # executes 2026-10-15 03:30 UTC and compacts dt=2026-10-14
    start_date=datetime(2026, 10, 14),
    catchup=True,
    max_active_runs=1,
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": email_on_failure(),
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
):
    for feed in ["service_alerts", "trip_updates", "vehicle_positions"]:
        BashOperator(
            task_id=f"compact_rt_{feed}",
            pool="rt_compaction_pool",
            append_env=True,
            retries=3,
            retry_delay=timedelta(minutes=10),
            retry_exponential_backoff=True,
            max_retry_delay=timedelta(hours=1),
            bash_command=(
                "python3 $HOME/gcs/plugins/scripts/gtfs_rt_compactor.py "
                + feed
                + " {{ ds }} --verbose"
            ),
        )
