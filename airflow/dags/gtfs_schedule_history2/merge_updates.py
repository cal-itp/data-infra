# ---
# python_callable: main
# provide_context: true
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

# This MERGE statement uses a hash of all of the columns of the table, except for
# extracted_at. But because this requires TO_JSON_STRING on a table, I had to
# remove calitp_extracted_at, and then re-insert it as execution date. An
# alternative (used by DBT) is to create a surrogate key by coercing the columns
# of interest to a string and then concatenating them.
SQL_TEMPLATE = """
MERGE `{target}` T
USING (
  WITH
    tbl_files_today AS (
      SELECT * EXCEPT(calitp_extracted_at) FROM `{source}`
      WHERE _FILE_NAME LIKE "{bucket_like_str}"
    ),
    tbl_hash AS (
      SELECT
        *
        , DATE("{execution_date}") as calitp_extracted_at
        , DATE(NULL) as calitp_deleted_at
        , TO_BASE64(MD5(TO_JSON_STRING(tbl_files_today))) AS calitp_hash
      FROM
        tbl_files_today
    ),
    feed_ids_today AS (
      SELECT DISTINCT calitp_itp_id, calitp_url_number
      FROM tbl_hash
    ),
    missing_entries AS (
      SELECT t1.calitp_hash AS calitp_hash
      FROM `{target}` t1
      FULL JOIN feed_ids_today t2
        ON
            t1.calitp_itp_id=t2.calitp_itp_id
            AND t1.calitp_url_number=t2.calitp_url_number
      WHERE
        t1.calitp_deleted_at IS NULL
        AND t2.calitp_itp_id IS NULL
    )
  SELECT
    t1.* EXCEPT(calitp_hash)
    , COALESCE(t1.calitp_hash, t2.calitp_hash) AS calitp_hash
  FROM tbl_hash t1
  FULL JOIN missing_entries t2
    USING(calitp_hash)
) S
ON
  T.calitp_hash = S.calitp_hash
WHEN NOT MATCHED BY TARGET THEN
    INSERT ROW
WHEN NOT MATCHED BY SOURCE AND T.calitp_deleted_at IS NULL THEN
    UPDATE
        SET calitp_deleted_at = DATE("{execution_date}")

"""


def merge_updates(table_name, execution_date, **kwargs):
    from calitp import get_engine, get_bucket, format_table_name
    from sqlalchemy import sql

    bucket_like_str = (
        f"{get_bucket()}/schedule/processed/{execution_date}_%/{table_name}.txt"
    )

    sql_code = SQL_TEMPLATE.format(
        target=format_table_name(f"{DST_SCHEMA}.{table_name}"),
        source=format_table_name(f"{SRC_SCHEMA}.{table_name}"),
        table_feed_updates=format_table_name(f"{SRC_SCHEMA}.calitp_feed_updates"),
        bucket_like_str=bucket_like_str,
        execution_date=execution_date.to_date_string(),
    )

    engine = get_engine()
    engine.execute(sql.text(sql_code))


def main(**kwargs):
    table_names = create_tables()

    for table_name in table_names:
        # TODO: remove validation report from included tables
        if table_name == "validation_report":
            continue

        merge_updates(table_name, **kwargs)
