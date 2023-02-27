# ---
# python_callable: email_failures
# provide_context: true
# dependencies:
#   - download_schedule_feeds
# trigger_rule: all_done
# ---
import datetime

import pandas as pd
from calitp_data.config import is_development

from airflow.models.taskinstance import TaskInstance
from airflow.utils.email import send_email


def email_failures(task_instance: TaskInstance, execution_date, **kwargs):
    # use pandas begrudgingly for email HTML since the old task used it
    failures_df = pd.DataFrame(
        task_instance.xcom_pull(
            task_ids="download_schedule_feeds", key="download_failures"
        )
    )
    if failures_df.empty:
        html_content = f"All feeds were downloaded successfully on {execution_date}!"
    else:
        html_report = failures_df.to_html(border=False)

        html_content = f"""\
    NOTE: These failures come from the v2 of the GTFS Schedule downloader.

    The following agency GTFS feeds could not be extracted on {execution_date}:

    {html_report}
    """

    if is_development():
        print(
            f"Skipping since in development mode! Would have emailed {failures_df.shape[0]} failures."
        )
        print(html_content)
    else:
        send_email(
            to=[
                "laurie.m@jarv.us",
                "andrew.v@jarv.us",
                "evan.siroky@dot.ca.gov",
                "hunter.owens@dot.ca.gov",
                "jameelah.y@jarv.us",
                "olivia.ramacier@dot.ca.gov",
            ],
            html_content=html_content,
            subject=(
                f"Operator GTFS Errors for {datetime.datetime.now().strftime('%Y-%m-%d')}"
            ),
        )
