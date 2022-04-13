{% macro get_latest_schedule_data(latest_only_source, table_name) %}

-- select rows from table_name
-- where calitp_deleted_at == 2099-01-01 (i.e., not yet deleted)
-- and ITP ID + URL number is in latest agencies.yml per latest_only_source table
-- latest_only_source table should be equivalent to
-- gtfs_views_staging.calitp_feeds and have a calitp_id_in_latest column

        WITH is_in_latest AS (
            SELECT DISTINCT
                calitp_itp_id,
                calitp_url_number,
                calitp_id_in_latest
            FROM {{ latest_only_source }}
            WHERE calitp_id_in_latest
        )

        SELECT
            t1.* EXCEPT(calitp_deleted_at)
        FROM gtfs_views_staging.{{ table_name }}_clean t1
        LEFT JOIN is_in_latest t2
            USING(calitp_itp_id, calitp_url_number)
        WHERE t1.calitp_deleted_at = '2099-01-01'
        AND t2.calitp_id_in_latest

{% endmacro %}
