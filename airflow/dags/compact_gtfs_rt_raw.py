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
