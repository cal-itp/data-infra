import os

import requests


def log_group_failure_to_slack(context):
    # pointed at #alerts-data-infra as of 2024-02-05
    CALITP_SLACK_URL = os.environ.get("CALITP_SLACK_URL")

    if not CALITP_SLACK_URL:
        print("Skipping email to slack channel. No CALITP_SLACK_URL in environment")
    else:
        try:
            task_instance = context.get("task_instance")
            dag_id = context.get("dag").dag_id
            task_id = task_instance.task_id
            log_url = task_instance.log_url
            execution_date = context.get("execution_date")

            message = f"""
            Task Failed: {dag_id}.{task_id}
            Execution Date: {execution_date}

            <{log_url}| Check Log >
            """
            requests.post(CALITP_SLACK_URL, json={"text": message})
            print(f"Slack notification sent: {message}")
        except Exception as e:
            # This is very broad but we want to try to log _any_ exception to slack
            print(f"Slack notification failed: {type(e)}")
            requests.post(
                CALITP_SLACK_URL, json={"text": f"failed to log {type(e)} to slack"}
            )
