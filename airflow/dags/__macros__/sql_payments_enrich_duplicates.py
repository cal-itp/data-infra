def sql_enrich_duplicates(schema_tbl, key_columns, order_by_columns):

    partition_keys = ", ".join(key_columns)
    order_keys = ", ".join(order_by_columns)

    return f"""
        WITH

        hashed AS (
            SELECT
                *,
                TO_BASE64(MD5(TO_JSON_STRING(T))) AS calitp_hash,
                _FILE_NAME AS calitp_file_name,
                REGEXP_EXTRACT(
                    _FILE_NAME,
                    '.*/[0-9]{{4}}-[0-9]{{2}}-[0-9]{{2}}_(.*)_[0-9]{{12}}_.*'
                ) AS calitp_export_account,
                PARSE_DATETIME(
                    '%Y%m%d%H%M',
                    REGEXP_EXTRACT(_FILE_NAME, '.*_([0-9]{{12}})_.*')
                ) AS calitp_export_datetime
            FROM {schema_tbl} T
        ),

        hashed_duped AS (
            SELECT
                *,
                COUNT(*) OVER (partition by calitp_hash) AS calitp_n_dupes,
                COUNT(*) OVER (partition by {partition_keys}) AS calitp_n_dupe_ids,
                ROW_NUMBER()
                  OVER (
                      PARTITION BY {partition_keys}
                      ORDER BY {order_keys}
                  )
                  AS calitp_dupe_number
            FROM hashed

        )

        SELECT * FROM hashed_duped
    """
