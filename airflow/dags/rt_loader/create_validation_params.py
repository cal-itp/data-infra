# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - external_calitp_validation_params
# external_dependencies:
#   - gtfs_loader: calitp_feed_status
# ---
import pandas as pd
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

    # This prefix limits the validation to only 1 hour of data currently
    glob = execution_date.replace(minute=0, second=0).format('YYYY-MM-DDTHH*')
    prefix_path_rt = f"gtfs-data/rt/{glob}"

    raw_params["entity"] = [
        ("service_alerts", "trip_updates", "vehicle_positions")
    ] * len(raw_params)
    params = raw_params.explode("entity").reset_index(drop=True)

    params = pd.concat(
        [
            params,
            params.apply(
                lambda row: {
                    "gtfs_schedule_path": f"{prefix_path_schedule}/{row.calitp_itp_id}_{row.calitp_url_number}",
                    "gtfs_rt_glob_path": f"{prefix_path_rt}/{row.calitp_itp_id}/{row.calitp_url_number}/*{row.entity}*",
                    "output_filename": row.entity,
                },
                axis="columns",
                result_type="expand",
            ),
        ],
        axis="columns",
    )

    path = f"rt-processed/calitp_validation_params/{execution_date}.csv"
    print(f"saving {params.shape[0]} validation params to {path}")
    save_to_gcfs(
        params.to_csv(index=False).encode(),
        path,
        use_pipe=True,
    )
