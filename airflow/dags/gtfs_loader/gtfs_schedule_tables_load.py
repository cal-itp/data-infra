# ---
# python_callable: main
# dependencies:
#   - calitp_feed_status
#   - gtfs_schedule_history_load
# ---

from sqlalchemy import sql
from calitp import get_table, query_sql, write_table
from calitp.config import get_bucket
from calitp.storage import get_fs

GTFS_DATA_PATH = "{bucket}/schedule/processed/{extracted_at}_{itp_id}_{url_number}"

QUERY_LATEST_TABLES = """
SELECT calitp_itp_id, calitp_url_number, calitp_extracted_at
FROM gtfs_schedule_history.calitp_feed_status
WHERE is_latest_load
"""


def main():
    fs = get_fs()

    df_loading = get_table(
        "gtfs_schedule_history.calitp_included_gtfs_tables", as_df=True
    )

    data_paths = (
        query_sql(QUERY_LATEST_TABLES, as_df=True)
        .rename(columns=lambda s: s.replace("calitp_", ""))
        .apply(lambda d: GTFS_DATA_PATH.format(bucket=get_bucket(), **d), axis=1)
        .tolist()
    )

    # double check that no paths we are attempting to load are missing from
    # schedule/processed. Since the validation results are also put there for
    # each feed daily, we look for a specific file: routes.txt.
    missing_paths = list(filter(lambda p: not fs.exists(f"{p}/routes.txt"), data_paths))
    if missing_paths:
        raise Exception("Missing processed data for loading: %s" % missing_paths)

    for _, (tbl_name, tbl_file) in df_loading[["table_name", "file_name"]].iterrows():
        file_paths = [f"{path}/{tbl_file}" for path in data_paths]

        src_table = get_table(f"gtfs_schedule_history.{tbl_name}")
        q = sql.select([sql.text("*")], from_obj=src_table).where(
            sql.column("_FILE_NAME").in_(file_paths)
        )

        write_table(q, f"gtfs_schedule.{tbl_name}", verbose=True)
