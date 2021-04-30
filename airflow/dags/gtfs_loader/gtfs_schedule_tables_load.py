# ---
# python_callable: main
# dependencies:
#   - calitp_feed_latest
#   - gtfs_schedule_history_load
# ---

from sqlalchemy import sql
from calitp import get_bucket, get_table, write_table

GTFS_DATA_PATH = "{bucket}/schedule/processed/{extracted_at}_{itp_id}_{url_number}"


def main():

    df_loading = get_table(
        "gtfs_schedule_history.calitp_included_gtfs_tables", as_df=True
    )

    data_paths = (
        get_table("gtfs_schedule_history.calitp_feed_latest", as_df=True)
        .rename(columns=lambda s: s.replace("calitp_", ""))
        .apply(lambda d: GTFS_DATA_PATH.format(bucket=get_bucket(), **d), axis=1)
        .tolist()
    )

    for _, (tbl_name, tbl_file) in df_loading[["table_name", "file_name"]].iterrows():
        file_paths = [f"{path}/{tbl_file}" for path in data_paths]

        src_table = get_table(f"gtfs_schedule_history.{tbl_name}")
        q = src_table.select(sql.text("*")).where(
            sql.column("_FILE_NAME").in_(file_paths)
        )

        write_table(q, f"gtfs_schedule.{tbl_name}", verbose=True)
