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
  T.calitp_deleted_at IS NULL
  AND T.calitp_hash = S.calitp_hash
WHEN NOT MATCHED BY TARGET THEN
    INSERT ROW
WHEN NOT MATCHED BY SOURCE AND T.calitp_deleted_at IS NULL THEN
    UPDATE
        SET calitp_deleted_at = DATE("{execution_date}")

"""
