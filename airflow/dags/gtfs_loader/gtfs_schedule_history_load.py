# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - calitp_feed_updates
#   - validation_report_process
# ---

import pandas as pd

from calitp.config import get_bucket
from calitp.storage import get_fs
from calitp import get_table
from utils import _keep_columns

# Note that destination includes date in the folder name, so that we can use
# a single wildcard to in the external table source url
SRC_DIR = "schedule/{execution_date}/{itp_id}_{url_number}"
DST_DIR = "schedule/processed/{date_string}_{itp_id}_{url_number}"
VALIDATION_REPORT = "validation_report.json"

DATASET = "gtfs_schedule_history"


def main(execution_date, ti, **kwargs):
    tables = get_table(f"{DATASET}.calitp_included_gtfs_tables", as_df=True)

    # TODO: replace w/ pybigquery pulling schemas directly from tables
    # pull schemas from external table tasks. these tasks only run once, so their
    # xcom data is stored as a prior date.
    schemas = [get_table(f"{DATASET}.{t}").columns.keys() for t in tables.table_name]
    # ti.xcom_pull(
    #     dag_id="gtfs_schedule_history", task_ids=tables, include_prior_dates=True
    # )

    # fetch latest feeds that need loading  from warehouse ----
    date_string = execution_date.to_date_string()

    tbl_feed = get_table(f"{DATASET}.calitp_feed_updates")
    q_today = tbl_feed.select().where(tbl_feed.c.calitp_extracted_at == date_string)

    df_latest_updates = (
        pd.read_sql(q_today, q_today.bind)
        .rename(columns=lambda s: s.replace("calitp_", ""))
        .convert_dtypes()
    )

    # load new feeds ----
    print(f"Number of feeds being loaded: {df_latest_updates.shape[0]}")

    ttl_feeds_copied = 0
    for k, row in df_latest_updates.iterrows():

        src_dir = SRC_DIR.format(execution_date=execution_date, **row)
        dst_dir = DST_DIR.format(date_string=date_string, **row)

        # only handle today's updated data (backfill dag to run all) ----

        # if fs.exists(f"{bucket}/dst_dir)
        #    continue

        # copy processed validator results ----
        fs = get_fs()
        bucket = get_bucket()

        src_validator = f"{bucket}/{src_dir}/processed/{VALIDATION_REPORT}"
        dst_validator = f"{bucket}/{dst_dir}/{VALIDATION_REPORT}"

        print(f"Copying from {src_validator} to {dst_validator}")

        fs.copy(src_validator, dst_validator)

        # process and copy over tables into external table folder ----
        table_details = zip(tables.file_name, tables.is_required, schemas)
        for table_file, is_required, colnames in table_details:
            # validation report handled above, since it is in a subfolder.
            # this is a side-effect of it technically not being an extraction,
            # and we might want to re-create it (and put results in "processed")
            if table_file == VALIDATION_REPORT:
                continue

            src_path = f"{src_dir}/{table_file}"
            dst_path = f"{dst_dir}/{table_file}"

            print(f"Copying from {src_path} to {dst_path}")

            if not is_required and not fs.exists(f"{bucket}/{src_path}"):
                print(f"Skipping missing optional file: {src_path}")
            else:
                _keep_columns(
                    src_path,
                    dst_path,
                    colnames,
                    row["itp_id"],
                    row["url_number"],
                    date_string,
                )

        ttl_feeds_copied += 1

        print("total feeds copied:", ttl_feeds_copied)
