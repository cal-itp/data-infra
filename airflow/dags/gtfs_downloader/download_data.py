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

import gcsfs
import pandas as pd

from pathlib import Path

SRC_DIR = "/tmp/gtfs-data/schedule"
DST_DIR = "gs://gtfs-data/schedule"


class NoFeedError(Exception):
    """
    No Feed / Feed Error base
    class. Placeholder for now.
    """

    pass


def save_to_gcfs(src_path, dst_path, gcs_project="cal-itp-data-infra", **kwargs):
    """Convenience function for saving files from disk to google cloud storage."""

    # TODO: this should be moved into a package of utility functions, and
    #       allow disabling via environment variable, so we can develop against
    #       airflow without pushing to the cloud

    fs = gcsfs.GCSFileSystem(project=gcs_project, token="cloud")
    fs.put(str(src_path), str(dst_path), **kwargs)


def download_url(url, itp_id, url_number, execution_date):
    """
    Download a URL as a task item
    using airflow. **kwargs are airflow
    """

    headers = {
        "User-Agent": (
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4)"
            "AppleWebKit/537.36 (KHTML, like Gecko)"
            "Chrome/83.0.4103.97 Safari/537.36"
        )
    }
    if pd.isna(itp_id):
        raise NoFeedError("missing itp_id")

    try:
        r = requests.get(url, headers=headers)
        r.raise_for_status()
    except requests.exceptions.HTTPError as err:
        logging.warning(f"No feed found for {url}, {err}")
        raise NoFeedError("error: HTTPError")
    except UnicodeError:
        # this occurs when a misformatted url is given
        raise NoFeedError("error: UnicodeError")

    try:
        z = zipfile.ZipFile(io.BytesIO(r.content))
        # replace here with s3fs
        rel_path = Path(f"{execution_date}/{int(itp_id)}/{int(url_number)}")
        src_path = SRC_DIR / rel_path
        dst_path = DST_DIR / rel_path

        src_path.mkdir(parents=True, exist_ok=True)
        z.extractall(src_path)

        save_to_gcfs(src_path, dst_path, recursive=True)
    except zipfile.BadZipFile:
        logging.warning(f"failed to zipfile {url}")
        raise NoFeedError("error: BadZipFile")


def downloader(task_instance, execution_date, **kwargs):
    provider_set = task_instance.xcom_pull(task_ids="generate_provider_list")
    url_status = []

    for row in provider_set:
        print(row)
        try:
            download_url(
                row["gtfs_schedule_url"],
                row["itp_id"],
                row["url_number"],
                execution_date,
            )

            status = "success"
        except NoFeedError as e:
            logging.warn(f"error downloading agency {row['agency_name']}")
            logging.info(e)

            status = str(e)

        url_status.append(status)

    df_status = pd.DataFrame(provider_set).assign(status=url_status)

    src_path = Path(SRC_DIR) / f"{execution_date}/status.csv"
    dst_path = Path(DST_DIR) / f"{execution_date}/status.csv"

    df_status.convert_dtypes().to_csv(src_path)
    save_to_gcfs(src_path, dst_path)

    error_agencies = df_status[lambda d: d.status != "success"].agency_name.tolist()
    logging.info(f"error agencies: {error_agencies}")

    return error_agencies
