# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - wait_for_external_tables
# external_dependencies:
#   - gtfs_downloader: download_data
# ---

from utils import _keep_columns
from calitp import get_table


# src_uris: "schedule/{{execution_date}}/status.csv"
# dst_table_name: "gtfs_schedule.calitp_status"


def main(execution_date, ti, **kwargs):
    # pull schemas from external table tasks. these tasks only run once, so their
    # xcom data is stored as a prior date.
    tbl_status = get_table("gtfs_schedule_history.calitp_status")
    colnames = [c.name for c in tbl_status.columns]

    src_uri = f"schedule/{execution_date}/status.csv"
    dst_uri = f"schedule/{execution_date}/processed/status.csv"

    date_string = execution_date.to_date_string()
    _keep_columns(src_uri, dst_uri, colnames, extracted_at=date_string)
