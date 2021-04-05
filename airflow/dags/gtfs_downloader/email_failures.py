# ---
# python_callable: email_failures
# provide_context: true
# dependencies:
#   - download_data
# ---

import datetime
from airflow.utils.email import send_email


def email_failures(task_instance, **kwargs):
    status = task_instance.xcom_pull(task_ids="download_data")
    error_agencies = status["errors"]

    # email out error agencies
    email_template = (
        "The follow agencies failed to have GTFS a GTFS feed at"
        "the URL or the Zip File Failed to extract:"
        f"{error_agencies}"
        "{{ ds }}"
    )
    send_email(
        to=["ruth.miller@dot.ca.gov", "hunter.owens@dot.ca.gov", "michael.c@jarv.us"],
        html_content=email_template,
        subject=(
            "Operator GTFS Errors for" f"{datetime.datetime.now().strftime('%Y-%m-%d')}"
        ),
    )
