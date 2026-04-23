import os
import shlex
from datetime import datetime

from dags import log_failure_to_slack
from src.dag_utils import log_group_failure_to_slack

from airflow import DAG
from airflow.models.param import Param
from airflow.operators.bash import BashOperator
from airflow.operators.latest_only import LatestOnlyOperator

# References:
#   Airflow params:     https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/params.html
#   dbt run CLI:        https://docs.getdbt.com/reference/commands/run
#   dbt node selection: https://docs.getdbt.com/reference/node-selection/syntax
#   dbt microbatch:     https://docs.getdbt.com/docs/build/incremental-microbatch#run-a-microbatch-model-from-the-cli

DBT_TARGET = os.environ.get("DBT_TARGET")


def _build_run_args(
    select, exclude, full_refresh, threads, event_time_start, event_time_end, vars
):
    # Rendered at task execution time via user_defined_macros, not at DAG parse time.
    flags = {
        "--select": select,
        "--exclude": exclude,
        "--threads": str(threads),
        "--event-time-start": event_time_start,
        "--event-time-end": event_time_end,
    }
    parts = []
    for flag, value in flags.items():
        if value and str(value).strip():
            tokens = shlex.split(str(value))
            parts += [flag] + [shlex.quote(t) for t in tokens]
    if full_refresh:
        parts.append("--full-refresh")
    if vars and str(vars).strip():
        parts += ["--vars", shlex.quote(str(vars).strip())]
    return " ".join(parts)


with DAG(
    dag_id="dbt_manual_run_with_args",
    tags=["dbt", "manual", "ad-hoc"],
    schedule=None,
    start_date=datetime(2025, 7, 21),
    catchup=False,
    user_defined_macros={
        "build_run_args": _build_run_args,
    },
    params={
        "select": Param(
            default="",
            type=["null", "string"],
            description=(
                "dbt --select expression. Space-separate multiple selectors. "
                "Examples: 'models/mart/gtfs', '+fct_stop_time_metrics', "
                "'+fct_scheduled_trips fct_monthly_routes+'."
            ),
        ),
        "exclude": Param(
            default="",
            type=["null", "string"],
            description="dbt --exclude expression. Space-separate multiple selectors.",
        ),
        "full_refresh": Param(
            default=False,
            type="boolean",
            description="Pass --full-refresh to dbt.",
        ),
        "threads": Param(
            default=4,
            type="integer",
            minimum=1,
            maximum=16,
            description="Number of dbt threads.",
        ),
        "event_time_start": Param(
            default="",
            type=["null", "string"],
            description=(
                "Microbatch --event-time-start (inclusive). "
                "Formats: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS. "
                "Leave blank to use dbt's default begin date."
            ),
        ),
        "event_time_end": Param(
            default="",
            type=["null", "string"],
            description=(
                "Microbatch --event-time-end (exclusive). "
                "Formats: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS. "
                "Leave blank to run through the current time."
            ),
        ),
        "vars": Param(
            default="",
            type=["null", "string"],
            description=(
                "dbt --vars expression as a YAML/JSON dict string. "
                "Example: '{my_var: my_value, other_var: 123}'."
            ),
        ),
    },
    default_args={
        "email": os.getenv("CALITP_NOTIFY_EMAIL"),
        "email_on_failure": True,
        "email_on_retry": False,
        "on_failure_callback": log_failure_to_slack,
    },
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    dbt_manual_with_args = BashOperator(
        task_id="dbt_manual_run_with_args",
        bash_command=(
            "dbt deps"
            " --project-dir /home/airflow/gcs/data/warehouse"
            " --profiles-dir /home/airflow/gcs/data/warehouse"
            " --profile calitp_warehouse"
            f" --target {DBT_TARGET}"
            " && dbt run"
            " --project-dir /home/airflow/gcs/data/warehouse"
            " --profiles-dir /home/airflow/gcs/data/warehouse"
            " --profile calitp_warehouse"
            f" --target {DBT_TARGET}"
            " {{ build_run_args(params.select, params.exclude,"
            " params.full_refresh, params.threads,"
            " params.event_time_start, params.event_time_end,"
            " params.vars) }}"
        ),
        on_failure_callback=log_group_failure_to_slack,
        retries=0,
    )

    latest_only >> dbt_manual_with_args
