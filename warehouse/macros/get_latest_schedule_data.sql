{% macro get_latest_schedule_data(latest_only_source, table_name, clean_table_name) %}

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
),
{{ table_name }}_latest AS (
    SELECT
        t1.* EXCEPT(calitp_deleted_at)
    FROM {{ clean_table_name }} t1
    LEFT JOIN is_in_latest t2
        USING(calitp_itp_id, calitp_url_number)
    WHERE t1.calitp_deleted_at = '2099-01-01'
    AND t2.calitp_id_in_latest
)
SELECT * FROM {{ table_name }}_latest
{% endmacro %}
