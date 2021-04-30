# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - calitp_feed_updates
#   - validation_report_process
# ---

import pandas as pd
from calitp import get_fs, get_bucket, format_table_name
from operators import _keep_columns

TABLES = ["agency", "routes", "stop_times", "stops", "trips"]

# Note that destination includes date in the folder name, so that we can use
# a single wildcard to in the external table source url
SRC_DIR = "schedule/{execution_date}/{itp_id}_{url_number}"
DST_DIR = "schedule/processed/{date_string}_{itp_id}_{url_number}"
VALIDATION_REPORT = "validation_report.json"


def main(execution_date, ti, **kwargs):
    src_loadables = format_table_name(
        "gtfs_schedule_history.calitp_included_gtfs_tables"
    )
    tables = pd.read_gbq(
        f"""
        SELECT * FROM `{src_loadables}`
    """
    ).table_name.tolist()

    # TODO: replace w/ pybigquery pulling schemas directly from tables
    # pull schemas from external table tasks. these tasks only run once, so their
    # xcom data is stored as a prior date.
    schemas = ti.xcom_pull(
        dag_id="gtfs_schedule_history", task_ids=tables, include_prior_dates=True
    )

    # fetch latest feeds that need loading  from warehouse ----
    date_string = execution_date.to_date_string()
    src_tbl = format_table_name("gtfs_schedule_history.calitp_feed_updates")

    df_latest_updates = (
        pd.read_gbq(
            f"""
        SELECT * FROM `{src_tbl}` WHERE calitp_extracted_at="{date_string}"
    """
        )
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
        for table, schema in zip(TABLES, schemas):
            src_path = f"{src_dir}/{table}.txt"
            dst_path = f"{dst_dir}/{table}.txt"

            print(f"Copying from {src_path} to {dst_path}")

            colnames = [entry["name"] for entry in schema]

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
