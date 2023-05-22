{% macro make_schedule_file_dimension_from_dim_schedule_feeds(dim_schedule_feeds, gtfs_file_table) %}
{{
    config(
        materialized='incremental',
        unique_key='key',
        cluster_by='feed_key',
    )
}}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ dim_schedule_feeds }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_dt', filter_dt_column='_dt', dev_lookback_days = None) }}
),

{{ gtfs_file_table.identifier }} AS (
    SELECT *
    FROM {{ gtfs_file_table }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_dt', filter_dt_column='_dt', dev_lookback_days = None) }}
)

-- define feed file's feed_key, effective dates, & gtfs_dataset_key based on dim_schedule_feeds
SELECT
    t2.key AS feed_key,
    t2._valid_from AS _feed_valid_from,
    t2.feed_timezone,
    t1.*,
FROM {{ gtfs_file_table.identifier }} AS t1
INNER JOIN dim_schedule_feeds AS t2
    ON t1.ts = t2._valid_from
    AND t1.base64_url = t2.base64_url

{% endmacro %}
