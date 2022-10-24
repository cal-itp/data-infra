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

import pandas as pd

from pathlib import Path

import yaml
from calitp.config import pipe_file_name, is_development
from calitp import save_to_gcfs

SRC_DIR = "/tmp/gtfs-data/schedule"
DST_DIR = "schedule"


class NoFeedError(Exception):
    """
    No Feed / Feed Error base
    class. Placeholder for now.
    """

    pass


def download_url(url, itp_id, url_number, execution_date, auth_headers=None):
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

    if auth_headers:
        headers.update(auth_headers.get((itp_id, url_number), {}))

    try:
        r = requests.get(url, headers=headers)
        r.raise_for_status()
    except requests.exceptions.HTTPError as err:
        logging.warning(f"No feed found for {url}, {err}")
        raise NoFeedError("error: HTTPError")
    except UnicodeError:
        # this occurs when a misformatted url is given
        raise NoFeedError("error: UnicodeError")
    except Exception as e:
        raise NoFeedError(f"error: {e}")

    try:
        z = zipfile.ZipFile(io.BytesIO(r.content))
        # replace here with s3fs
        rel_path = Path(f"{execution_date}/{int(itp_id)}_{int(url_number)}")
        src_path = SRC_DIR / rel_path
        dst_path = DST_DIR / rel_path

        src_path.mkdir(parents=True, exist_ok=True)
        z.extractall(src_path)

        full_path = save_to_gcfs(src_path, dst_path, recursive=True)
    except zipfile.BadZipFile:
        logging.warning(f"failed to zipfile {url}")
        raise NoFeedError("error: BadZipFile")

    return full_path


def downloader(task_instance, execution_date, **kwargs):
    """Download gtfs data from agency urls

    Returns dict of form {gtfs_paths, errors}
    """
    try:
        fname = pipe_file_name(
            "data/headers.filled.yml" if is_development() else "data/headers.yml"
        )

        with open(fname) as f:
            raw_headers = yaml.safe_load(f)
        auth_headers = {
            (url["itp_id"], url["url_number"]): record["header-data"]
            for record in raw_headers
            for url in record["URLs"]
            if "gtfs_schedule_url" in url["rt_urls"]
        }
        print(f"successfully loaded headers from {fname}")
    except Exception as e:
        logging.warn("error getting auth headers", e)
        auth_headers = {}

    provider_set = task_instance.xcom_pull(task_ids="generate_provider_list")
    url_status = []

    gtfs_paths = []
    for row in provider_set:
        print(row)
        try:
            res_path = download_url(
                row["gtfs_schedule_url"],
                row["itp_id"],
                row["url_number"],
                execution_date,
                auth_headers=auth_headers,
            )
            gtfs_paths.append(res_path)

            status = "success"
        except NoFeedError as e:
            logging.warn(f"error downloading agency {row['agency_name']}")
            logging.info(e)

            status = str(e)

        url_status.append(status)

    df_status = pd.DataFrame(provider_set).assign(status=url_status)

    src_path = Path(SRC_DIR) / f"{execution_date}/status.csv"
    dst_path = Path(DST_DIR) / f"{execution_date}/status.csv"

    df_status.convert_dtypes().to_csv(src_path, index=False)
    save_to_gcfs(src_path, dst_path)

    df_errors = df_status[lambda d: d.status != "success"]
    error_agencies = df_errors[["agency_name", "gtfs_schedule_url", "status"]]
    error_records = error_agencies.to_dict(orient="record")

    logging.info(f"error agencies: {error_agencies.agency_name.tolist()}")

    return {"gtfs_paths": gtfs_paths, "errors": error_records}
