import os
from datetime import datetime

from operators.gcs_to_gtfs_rt_command_operator import GCSToGTFSRTCommandOperator

from airflow import DAG, XComArg
from airflow.operators.bash import BashOperator

with DAG(
    dag_id="parse_and_validate_rt",
    tags=["gtfs", "gtfs-rt"],
    # Every hour at 15 minutes past the hour
    schedule="15 * * * *",
    start_date=datetime(2025, 9, 2),
    catchup=False,
    max_active_tasks=128,
):
    for process in ["parse", "validate"]:
        for feed in ["service_alerts", "trip_updates", "vehicle_positions"]:
            commands = GCSToGTFSRTCommandOperator(
                task_id=f"build_{process}_rt_{feed}",
                bucket=os.environ["CALITP_BUCKET__GTFS_RT_RAW"],
                process=process,
                feed=feed,
            )

            BashOperator.partial(
                task_id=f"{process}_rt_{feed}",
                pool=f"rt_{process}_pool",
                append_env=True,
                do_xcom_push=False,
            ).expand(bash_command=XComArg(commands))
