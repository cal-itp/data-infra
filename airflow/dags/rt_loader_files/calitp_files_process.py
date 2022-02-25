# ---
# python_callable: main
# provide_context: true
# task_concurrency: 4
# ---

"""
Process and dump files for gtfs_rt_history.calitp_files external table.
This is for the rt files extracted per feed every 20 seconds.
"""

from calitp import save_to_gcfs
from calitp.storage import get_fs
from calitp.config import get_bucket

import pandas as pd
import structlog

# FEED_DAILY_URI = "{bucket}/rt/{execution_date}T*


def glob_daily_files(date_string, fs, logger):
    # TODO: remove hard-coded project string

    # <datetime>/<itp_id>/<url_number>/<filename>
    path_to_glob = f"{get_bucket()}/rt/{date_string}*/*/*/*"
    logger.info("Globbing {}".format(path_to_glob))
    all_files = fs.glob(path_to_glob, detail=True)
    logger.info("Finished globbing")
    fs.dircache.clear()

    raw_res = pd.DataFrame(all_files.values())

    if not len(raw_res):
        logger.info("No data for this date")

        return

    # ----
    # Do some light pre-processing to add internal data

    ser_id = raw_res["name"].str.split("/")

    raw_res["calitp_itp_id"] = ser_id.str.get(-3).astype(int)
    raw_res["calitp_url_number"] = ser_id.str.get(-2).astype(int)
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
    output_path = f"rt-processed/calitp_files/{date_string}.csv"
    save_to_gcfs(
        res.to_csv(index=False).encode(), output_path, use_pipe=True,
    )


def main(execution_date, **kwargs):
    logger = structlog.get_logger()
    # run for both execution date and the day before
    # this ensures that ALL files are eventually picked up
    dates = [execution_date, execution_date.subtract(days=1)]
    fs = get_fs()
    for day in dates:
        date_string = day.to_date_string()
        glob_daily_files(date_string, fs, logger)
