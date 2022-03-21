# ---
# python_callable: email_failures
# provide_context: true
# dependencies:
#   - download_data
# ---

import datetime
from airflow.utils.email import send_email
from calitp.config import is_development
import pandas as pd


def email_failures(task_instance, ds, **kwargs):
    if is_development():
        print("Skipping since in development mode!")
        return

    status = task_instance.xcom_pull(task_ids="download_data")
    error_agencies = status["errors"]

    if len(error_agencies) > 0:
        html_report = pd.DataFrame(error_agencies).to_html(border=False)

        html_content = f"""\
The following agency GTFS feeds could not be extracted on {ds}:

{html_report}
"""
    else:
        html_content = "All feeds were downloaded successfully!"

    send_email(
        to=[
            "aaron@trilliumtransit.com",
            "blake.f@jarv.us",
            "evan.siroky@dot.ca.gov",
            "hunter.owens@dot.ca.gov",
            "jameelah.y@jarv.us",
            "juliet@trilliumtransit.com",
            "olivia.ramacier@dot.ca.gov",
        ],
        html_content=html_content,
        subject=(
            f"Operator GTFS Errors for {datetime.datetime.now().strftime('%Y-%m-%d')}"
        ),
    )
