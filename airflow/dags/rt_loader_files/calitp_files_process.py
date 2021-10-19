# ---
# python_callable: main
# provide_context: true
# task_concurrency: 4
# dependencies:
#   - external_calitp_files
# ---

"""
Process and dump files for gtfs_rt_history.calitp_files external table.
This is for the rt files extracted per feed every 20 seconds.
"""

from calitp import save_to_gcfs
from calitp.storage import get_fs

import pandas as pd

# FEED_DAILY_URI = "{bucket}/rt/{execution_date}T*


def main(execution_date, **kwargs):
    # TODO: remove hard-coded project string

    fs = get_fs()

    date_string = execution_date.to_date_string()

    # note that we will only use the prod bucket, even on staging, since the RT
    #
    # bucket = get_bucket()

    # <datetime>/<itp_id>/<url_number>/<filename>
    all_files = fs.glob(f"gs://gtfs-data/rt/{date_string}*/*/*/*", detail=True)
    fs.dircache.clear()

    raw_res = pd.DataFrame(all_files.values())

    if not len(raw_res):
        print("No data for this date")

        return

    # ----
    # Do some light pre-processing to add internal data

    ser_id = raw_res["name"].str.split("/")

    raw_res["calitp_itp_id"] = ser_id.str.get(-3)
    raw_res["calitp_url_number"] = ser_id.str.get(-2)
    raw_res["calitp_extracted_at"] = ser_id.str.get(-4)

    raw_res["full_path"] = raw_res["name"]
    raw_res["name"] = ser_id.str.get(-1)
    raw_res["md5_hash"] = raw_res["md5Hash"]

    res = raw_res[
        [
            "calitp_itp_id",
            "calitp_url_number",
            "calitp_extracted_at",
            "name",
            "size",
            "md5_hash",
        ]
    ]

    save_to_gcfs(
        res.to_csv(index=False).encode(),
        f"rt-processed/calitp_files/{date_string}.csv",
        use_pipe=True,
    )
