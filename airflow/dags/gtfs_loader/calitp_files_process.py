# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - valid_agency_paths
#   - wait_for_external_tables
# ---

"""
Process and dump files for gtfs_schedule_history.calitp_files external table.
This is for the files downloaded for an agency, as well as validator results.
"""

import pandas as pd

from calitp import save_to_gcfs
from calitp.config import get_bucket
from calitp.storage import get_fs

from utils import get_successfully_downloaded_feeds


def main(execution_date, **kwargs):
    fs = get_fs()
    bucket = get_bucket()

    successes = get_successfully_downloaded_feeds(execution_date)

    gtfs_file = []
    for ii, row in successes.iterrows():
        agency_folder = f"{row.itp_id}_{row.url_number}"
        agency_url = f"{bucket}/schedule/{execution_date}/{agency_folder}"

        dir_files = [x for x in fs.listdir(agency_url) if x["type"] == "file"]

        for x in dir_files:
            gtfs_file.append(
                {
                    "calitp_itp_id": row["itp_id"],
                    "calitp_url_number": row["url_number"],
                    "calitp_extracted_at": execution_date.to_date_string(),
                    "full_path": x["name"],
                    "name": x["name"].split("/")[-1],
                    "size": x["size"],
                    "md5_hash": x["md5Hash"],
                }
            )

    res = pd.DataFrame(gtfs_file)

    save_to_gcfs(
        res.to_csv(index=False).encode(),
        f"schedule/{execution_date}/processed/files.csv",
        use_pipe=True,
    )
