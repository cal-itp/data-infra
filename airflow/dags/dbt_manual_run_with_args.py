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
        v = str(vars).strip()
        if (v.startswith('"') and v.endswith('"')) or (
            v.startswith("'") and v.endswith("'")
        ):
            v = v[1:-1]
        parts += ["--vars", shlex.quote(v)]
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
            description_md=(
                "dbt `--select` expression. Space-separate multiple selectors.\n\n"
                "**Examples:**\n"
                "- `models/mart/gtfs`\n"
                "- `+fct_stop_time_metrics`\n"
                "- `+fct_scheduled_trips fct_monthly_routes+`"
            ),
        ),
        "exclude": Param(
            default="",
            type=["null", "string"],
            description_md=(
                "dbt `--exclude` expression. Space-separate multiple selectors."
            ),
        ),
        "full_refresh": Param(
            default=False,
            type="boolean",
            description_md="Pass `--full-refresh` to dbt.",
        ),
        "threads": Param(
            default=4,
            type="integer",
            minimum=1,
            maximum=16,
            description_md="Number of threads to run with.",
        ),
        "event_time_start": Param(
            default="",
            type=["null", "string"],
            description_md=(
                "Microbatch `--event-time-start` (inclusive).\n\n"
                "**Formats:**\n"
                "- `YYYY-MM-DD`\n"
                "- `YYYY-MM-DDTHH:MM:SS`\n\n"
                "Leave blank to use dbt's default begin date."
            ),
        ),
        "event_time_end": Param(
            default="",
            type=["null", "string"],
            description_md=(
                "Microbatch `--event-time-end` (exclusive).\n\n"
                "**Formats:**\n"
                "- `YYYY-MM-DD`\n"
                "- `YYYY-MM-DDTHH:MM:SS`\n\n"
                "Leave blank to run through the current time."
            ),
        ),
        "vars": Param(
            default="",
            type=["null", "string"],
            format="multiline",
            description_md=(
                "dbt `--vars` expression as a YAML or JSON dict. "
                "You do not need to wrap your entire input in quotes.\n\n"
                "```\n"
                "**YAML block (multi-line):**\n"
                "```\n"
                "DBT_INCREMENTAL_START_DATE: '2026-04-20'\n"
                "DBT_INCREMENTAL_END_DATE: '2026-04-21'\n"
                "```\n"
                "**JSON:**\n"
                "```\n"
                '{"DBT_INCREMENTAL_START_DATE": "2026-04-20", '
                '"DBT_INCREMENTAL_END_DATE": "2026-04-21"}\n'
                "```"
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
