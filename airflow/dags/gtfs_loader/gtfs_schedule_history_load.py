# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - calitp_feed_updates
# ---

import pandas as pd
from calitp import get_table, save_to_gcfs
from calitp.config import get_bucket
from calitp.storage import get_fs
from pandas.errors import ParserError

import constants
from utils import _keep_columns

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

    # this zip needs to be converted to a list in order to be iterated through multiple
    # times in an inner loop per each feed update below. This resolves a regression as
    # described in https://github.com/cal-itp/data-infra/issues/848.
    table_details = list(zip(tables.file_name, tables.is_required, schemas))
    fs = get_fs()
    bucket = get_bucket()

    # load new feeds ----
    print(f"Number of feeds being loaded: {df_latest_updates.shape[0]}")

    ttl_feeds_copied = 0
    feed_tables_process_results = []
    feed_process_resuls = []
    for k, row in df_latest_updates.iterrows():
        # initialize variable to track whether a parsing error occurred and which tables
        # were loaded so far
        parse_error_encountered_in_this_feed = False
        id_and_url = f"{row['itp_id']}_{row['url_number']}"

        # process and copy over tables into external table folder ----
        for table_file, is_required, colnames in table_details:
            # validation report handled in a separate task, since it is in a subfolder
            # and should be ran separately in case the feed is unparseable.
            if table_file == constants.VALIDATION_REPORT:
                continue

            src_path = "/".join(
                ["schedule", str(execution_date), id_and_url, table_file]
            )
            dst_path = "/".join(
                ["schedule", "processed", f"{date_string}_{id_and_url}", table_file]
            )

            print(f"Copying from {src_path} to {dst_path}")

            if not is_required and not fs.exists(f"{bucket}/{src_path}"):
                print(f"Skipping missing optional file: {src_path}")
            else:
                parse_error_encountered = False
                try:
                    _keep_columns(
                        src_path,
                        dst_path,
                        colnames,
                        row["itp_id"],
                        row["url_number"],
                        date_string,
                    )
                except ParserError:
                    print(
                        f"Fatal parsing error encountered in {table_file} for id and "
                        "URL: {id_and_url}."
                    )
                    parse_error_encountered = True
                    parse_error_encountered_in_this_feed = True

                feed_tables_process_results.append(
                    {
                        "calitp_itp_id": row["itp_id"],
                        "calitp_url_number": row["url_number"],
                        "calitp_extracted_at": execution_date.to_date_string(),
                        "filename": table_file,
                        "parse_error_encountered": parse_error_encountered,
                    }
                )

        # note the parse result for this feed
        feed_process_resuls.append(
            {
                "calitp_itp_id": row["itp_id"],
                "calitp_url_number": row["url_number"],
                "calitp_extracted_at": execution_date.to_date_string(),
                "parse_error_encountered": parse_error_encountered_in_this_feed,
            }
        )

        ttl_feeds_copied += 1

        print("total feeds copied:", ttl_feeds_copied)

    # save feed and feed table process results to external tables
    save_to_gcfs(
        pd.DataFrame(feed_process_resuls).to_csv(index=False).encode(),
        f"schedule/{execution_date}/processed/feed_parse_result.csv",
        use_pipe=True,
    )
    save_to_gcfs(
        pd.DataFrame(feed_tables_process_results).to_csv(index=False).encode(),
        f"schedule/{execution_date}/processed/feed_tables_parse_result.csv",
        use_pipe=True,
    )
