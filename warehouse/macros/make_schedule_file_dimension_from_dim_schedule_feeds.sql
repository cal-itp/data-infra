{% macro make_schedule_file_dimension_from_dim_schedule_feeds(dim_schedule_feeds, gtfs_file_table) %}
{{
    config(
        materialized='incremental',
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
    {% if is_incremental() %}
    WHERE _valid_from > '{{ max_ts }}'
    {% endif %}
),

{{ gtfs_file_table.identifier }} AS (
    SELECT *
    FROM {{ gtfs_file_table }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE _dt >= '{{ var("FULL_REFRESH_SCHEDULE_START") }}'
    {% endif %}
)

-- define feed file's feed_key, effective dates, & gtfs_dataset_key based on dim_schedule_feeds
SELECT
    t2.key AS feed_key,
    t2._valid_from AS _feed_valid_from,
    t1.*,
FROM {{ gtfs_file_table.identifier }} AS t1
INNER JOIN dim_schedule_feeds AS t2
    ON t1.ts = t2._valid_from
    AND t1.base64_url = t2.base64_url

{% endmacro %}
