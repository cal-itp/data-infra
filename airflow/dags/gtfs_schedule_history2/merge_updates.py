# ---
# python_callable: main
# provide_context: true
# external_dependencies:
#   - gtfs_loader: gtfs_schedule_history_load
# ---

# This task looks up all included gtfs tables, then..
#   * Creates an empty copy of each in DST_SCHEMA
#   * Runs daily snapshots (type 2)
# It can be re-run for the current day, but depends on past tasks.

# TODO: Normally this task would be split into one task per table being updated.
# However, because airflow v1 doesn't have task groups, it's probably easier
# to keep as one big task for now. Once we upgrade to airflow v2, we can create
# a special task group operator, that takes the names of each table, and generates
# one task per table.
# TODO: split out operators.py into submodules and move logic into there.

from merge_sql import SQL_TEMPLATE
import structlog

SRC_SCHEMA = "gtfs_schedule_history"
DST_SCHEMA = "gtfs_schedule_type2"


# Task 1: Create tables =======================================================


def create_tables(names=None):
    """Fetch included gtfs tables. If they don't exist, then create them."""

    from calitp import get_table, write_table

    if names is None:
        names = get_table(
            f"{SRC_SCHEMA}.calitp_included_gtfs_tables", as_df=True
        ).table_name.tolist()

    for src_name in names:
        sql_query = f"""
        SELECT
          *
          , DATE(NULL) AS calitp_deleted_at
          , "" AS calitp_hash
        FROM `{SRC_SCHEMA}.{src_name}`
        LIMIT 0
        """
        write_table(
            sql_query,
            f"{DST_SCHEMA}.{src_name}",
            replace=False,
            if_not_exists=True,
            partition_by="calitp_deleted_at",
        )

    return names


# Task 2: Daily type 2 merge ==================================================


def merge_updates(table_name, execution_date, **kwargs):
    from calitp import get_engine
    from calitp.config import get_bucket, format_table_name
    from sqlalchemy import sql

    date_string = execution_date.to_date_string()

    bucket_like_str = (
        f"{get_bucket()}/schedule/processed/{date_string}_%/{table_name}.txt"
    )

    sql_code = SQL_TEMPLATE.format(
        target=format_table_name(f"{DST_SCHEMA}.{table_name}"),
        source=format_table_name(f"{SRC_SCHEMA}.{table_name}"),
        table_feed_updates=format_table_name(f"{SRC_SCHEMA}.calitp_feed_updates"),
        bucket_like_str=bucket_like_str,
        execution_date=date_string,
    )

    engine = get_engine()
    engine.execute(sql.text(sql_code))


def main(**kwargs):
    logger = structlog.get_logger()
    table_names = create_tables()

    for table_name in table_names:
        logger.info("Processing table", table_name=table_name)
        # TODO: remove validation report from included tables
        if table_name == "validation_report":
            continue

        merge_updates(table_name, **kwargs)
