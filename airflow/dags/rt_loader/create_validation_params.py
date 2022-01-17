# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - external_calitp_validation_params
# external_dependencies:
#   - gtfs_loader: calitp_feed_status
# ---

from calitp import query_sql, save_to_gcfs
from calitp.config import get_bucket


def main(execution_date, **kwargs):
    date_string = execution_date.to_date_string()

    raw_params = query_sql(
        f"""
        SELECT
            calitp_itp_id,
            calitp_url_number,
            calitp_extracted_at
        FROM gtfs_schedule_history.calitp_feed_status
        WHERE
            is_extract_success
            AND NOT is_parse_error
            AND calitp_extracted_at = "{date_string}"
        """,
        as_df=True,
    )

    # Note that raw RT data is currently stored in the production bucket,
    # and not copied to the staging bucket
    prefix_path_schedule = f"{get_bucket()}/schedule/{execution_date}"
    prefix_path_rt = f"gtfs-data/rt/{date_string}T00:00:*"

    params = raw_params.assign(
        gtfs_schedule_path=lambda d: prefix_path_schedule
        + "/"
        + d.calitp_itp_id.astype(str)
        + "_"
        + d.calitp_url_number.astype(str),
        gtfs_rt_glob_path=lambda d: prefix_path_rt
        + "/"
        + d.calitp_itp_id.astype(str)
        + "/"
        + d.calitp_url_number.astype(str)
        + "/*",
    )

    save_to_gcfs(
        params.to_csv(index=False).encode(),
        f"rt-processed/calitp_validation_params/{date_string}.csv",
        use_pipe=True,
    )
