import os
from pathlib import Path

import requests
from gusty import create_dag

import airflow  # noqa

# pointed at #alerts-data-infra as of 2024-02-05
CALITP_SLACK_URL = os.environ.get("CALITP_SLACK_URL")

# DAG Directories =============================================================

# point to your dags directory (the one this file lives in)
dag_parent_dir = Path(__file__).parent

# assumes any subdirectories in the dags directory are Gusty DAGs (with METADATA.yml)
# (excludes subdirectories like __pycache__)
dag_directories = []
for child in dag_parent_dir.iterdir():
    if child.is_dir() and not str(child).endswith("__"):
        dag_directories.append(str(child))

# DAG Generation ==============================================================


def log_failure_to_slack(context):
    if not CALITP_SLACK_URL:
        print("Skipping email to slack channel. No CALITP_SLACK_URL in environment")
    else:
        try:
            ti = context["ti"]
            message = f"""
            Task Failed: {ti.dag_id}.{ti.task_id}
            Execution Date: {ti.execution_date}
            Try {ti.try_number} of {ti.max_tries}

            <{ti.log_url}| Check Log >
            """  # noqa: E221, E222

            requests.post(CALITP_SLACK_URL, json={"text": message})

        except Exception as e:
            # This is very broad but we want to try to log _any_ exception to slack
            requests.post(
                CALITP_SLACK_URL, json={"text": f"failed to log {type(e)} to slack"}
            )


for dag_directory in dag_directories:
    dag_id = os.path.basename(dag_directory)
    globals()[dag_id] = create_dag(
        dag_directory,
        tags=["default", "tags"],
        task_group_defaults={"tooltip": "this is a default tooltip"},
        wait_for_defaults={"retries": 24, "check_existence": True, "timeout": 10 * 60},
        latest_only=False,
        user_defined_macros={
            "image_tag": lambda: "development"
            if os.environ["AIRFLOW_ENV"] == "cal-itp-data-infra-staging"
            else "latest",
            "env_var": os.environ.get,
        },
        default_args={
            "on_failure_callback": log_failure_to_slack,
            # "on_retry_callback": log_failure_to_slack,
        },
    )
