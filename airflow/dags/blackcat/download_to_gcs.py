import requests
import gcsfs
import os
import logging
import datetime
import pandas as pd
from sqlalchemy import create_engine

# TODO: this should be swapped to use airflow credentials
TOKEN = os.environ.get("BLACKCAT_TOKEN")
ENDPOINT = (
    "https://bcf.pantherinternational.com/api/external/CreateCAJsonResult/client/BCG_CA"
)
DST_DIR = "gs://blackcat-data/"


def save_to_gcfs(src_path, dst_path, gcs_project="cal-itp-data-infra", **kwargs):
    """Convenience function for saving files from disk to google cloud storage."""

    # TODO: this should be moved into a package of utility functions, and
    #       allow disabling via environment variable, so we can develop against
    #       airflow without pushing to the cloud

    fs = gcsfs.GCSFileSystem(project=gcs_project, token="cloud")
    fs.put(str(src_path), str(dst_path), **kwargs)


def download_and_save_blackcat():
    """
    Download and save a sqlite3
    dump of the blackcat db to GCSFS
    """
    # Download the DAta
    r = requests.get(ENDPOINT, headers={"Subscription-Key": TOKEN})
    r.raise_for_status()
    data = r.json()
    dfs_dict = {}
    for table in data["Tables"]:
        tbl_name = table["Name"]
        try:
            col_list = [k["Column"] for k in table["Rows"][0]["Columns"]]
        except IndexError:
            logging.info(f"There are no columns in {tbl_name}")
        rows = []
        for row in table["Rows"]:
            values = [d["Value"] for d in row["Columns"]]
            rows.append(values)
        # dataframe it
        dfs_dict[tbl_name] = pd.DataFrame(rows, columns=col_list)
    logging.info(f"The total number of parsed tables is {len(dfs_dict)}")
    # create sqlite3 db in /tmp
    engine = create_engine("sqlite:////tmp/blackcat.sqlite")
    if os.path.exists("/tmp/blackcat.sqlite"):
        os.remove("/tmp/blackcat.sqlite")
    {v.to_sql(k, con=engine) for k, v in dfs_dict.items()}
    # upload it
    today = datetime.datetime.now().strftime("%Y-%m-%d")
    save_to_gcfs("/tmp/blackcat.sqlite", f"{DST_DIR}/{today}-blackcat.sqlite")
