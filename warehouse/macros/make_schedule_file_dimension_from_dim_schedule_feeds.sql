{% macro make_schedule_file_dimension_from_dim_schedule_feeds(dim_schedule_feeds, gtfs_file_table) %}
{{
    config(
        materialized='incremental',
        unique_key='key',
        cluster_by='feed_key',
    )
}}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max timestamp in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='_feed_valid_from', order_by = '_feed_valid_from DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ dim_schedule_feeds }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_feed_valid_from', filter_dt_column='_dt', dev_lookback_days = None) }}
),

{{ gtfs_file_table.identifier }} AS (
    SELECT *
    FROM {{ gtfs_file_table }}
    WHERE {{ incremental_where(default_start_var='GTFS_SCHEDULE_START', this_dt_column='_feed_valid_from', filter_dt_column='_dt', dev_lookback_days = None) }}
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
