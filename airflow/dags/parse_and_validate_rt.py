import os
from datetime import datetime

from airflow import DAG
from airflow.decorators import task
from airflow.operators.bash import BashOperator
from airflow.providers.google.cloud.hooks.gcs import GCSHook

with DAG(
    dag_id="parse_and_validate_rt",
    tags=["gtfs", "gtfs-rt"],
    # Every hour at 15 minutes past the hour
    schedule="15 * * * *",
    start_date=datetime(2025, 9, 2),
    catchup=False,
):

    def get_urls(files):
        base64_urls = []
        for path in files:
            for partition in path.split("/"):
                if partition.startswith("base64_url="):
                    base64_urls.append(partition.split("=")[1])
        return list(set(base64_urls))

    def build_command(process, data, datetime, url):
        return " ".join(
            [
                "python3",
                "$HOME/gcs/plugins/scripts/gtfs_rt_parser.py",
                process,
                data,
                datetime,
                "--base64url",
                url,
                "--verbose",
            ]
        )

    @task
    def build_commands(process, data, date, timestamp, datetime):
        hook = GCSHook()
        files = hook.list(
            bucket_name=os.environ["CALITP_BUCKET__GTFS_RT_RAW"].replace("gs://", ""),
            prefix=f"{data}/dt={date}/hour={timestamp}/",
        )
        return [
            build_command(process=process, data=data, datetime=datetime, url=url)
            for url in get_urls(files=files)
        ]

    build_parse_rt_vehicle_positions = build_commands(
        process="parse",
        data="vehicle_positions",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    build_parse_rt_service_alerts = build_commands(
        process="parse",
        data="service_alerts",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    build_parse_rt_trip_updates = build_commands(
        process="parse",
        data="trip_updates",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    build_validate_rt_vehicle_positions = build_commands(
        process="validate",
        data="vehicle_positions",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    build_validate_rt_service_alerts = build_commands(
        process="validate",
        data="service_alerts",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    build_validate_rt_trip_updates = build_commands(
        process="validate",
        data="trip_updates",
        date="{{ execution_date.format('YYYY-MM-DD') }}",
        timestamp="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss+00:00') }}",
        datetime="{{ execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH:mm:ss') }}",
    )

    BashOperator.partial(
        task_id="parse_rt_service_alerts", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_parse_rt_service_alerts)

    BashOperator.partial(
        task_id="parse_rt_trip_updates", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_parse_rt_trip_updates)

    BashOperator.partial(
        task_id="parse_rt_vehicle_positions", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_parse_rt_vehicle_positions)

    BashOperator.partial(
        task_id="validate_rt_service_alerts", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_validate_rt_service_alerts)

    BashOperator.partial(
        task_id="validate_rt_trip_updates", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_validate_rt_trip_updates)

    BashOperator.partial(
        task_id="validate_rt_vehicle_positions", append_env=True, do_xcom_push=False
    ).expand(bash_command=build_validate_rt_vehicle_positions)
