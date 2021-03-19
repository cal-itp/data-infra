# ---
# python_callable: downloader
# provide_context: true
# dependencies:
#   - generate_provider_list
# ---

"""
Download the state of CA GTFS files, async version
"""

import requests
import logging
import zipfile
import io
import pathlib
import datetime

import gcsfs
from airflow.utils.email import send_email


class NoFeedError(Exception):
    """
    No Feed / Feed Error base
    class. Placeholder for now.
    """

    pass


def download_url(url, itp_id, gcs_project, **kwargs):
    """
    Download a URL as a task item
    using airflow. **kwargs are airflow
    """
    run_time = kwargs["execution_date"]
    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4)"
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/83.0.4103.97 Safari/537.36"
        )
    }
    try:
        r = requests.get(url, headers=headers)
        r.raise_for_status()
    except requests.exceptions.HTTPError as err:
        logging.warning(f"No feed found for {url}, {err}")
        raise NoFeedError
    try:
        z = zipfile.ZipFile(io.BytesIO(r.content))
        # replace here with s3fs
        fs = gcsfs.GCSFileSystem(project=gcs_project, token="cloud")
        path = f"/tmp/gtfs-data/{run_time}/{int(itp_id)}"
        pathlib.Path(path).mkdir(parents=True, exist_ok=True)
        z.extractall(path)
        fs.put(
            path, f"gs://gtfs-data/schedule/{run_time}/{int(itp_id)}", recursive=True
        )
    except zipfile.BadZipFile:
        logging.warning(f"failed to zipfile {url}")
        raise NoFeedError


def downloader(**kwargs):
    provider_set = kwargs["task_instance"].xcom_pull(task_ids="generate_provider_list")
    error_agencies = []
    for row in provider_set:
        print(row)
        try:
            download_url(
                row["gtfs_schedule_url"], row["itp_id"], "cal-itp-data-infra", **kwargs
            )
        except Exception as e:
            logging.warn(f"error downloading agency {row['agency_name']}")
            logging.info(e)
            error_agencies.append(row["agency_name"])
            continue
    logging.info(f"error agencies: {error_agencies}")
    # email out error agencies
    email_template = (
        "The follow agencies failed to have GTFS a GTFS feed at"
        "the URL or the Zip File Failed to extract:"
        f"{error_agencies}"
        "{{ ds }}"
    )
    send_email(
        to=["ruth.miller@dot.ca.gov", "hunter.owens@dot.ca.gov"],
        html_content=email_template,
        subject=(
            "Operator GTFS Errors for" f"{datetime.datetime.now().strftime('%Y-%m-%d')}"
        ),
    )
