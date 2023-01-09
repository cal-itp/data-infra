{{ config(materialized='incremental') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max timestamp in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='_valid_from', order_by = '_valid_from DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
    {% if is_incremental() %}
    WHERE _valid_from > '{{ max_ts }}'
    {% endif %}
),

stg_gtfs_schedule__pathways AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__pathways') }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% else %}
    WHERE _valid_from >= DATE_SUB(CURRENT_DATE(), INTERVAL {{ var('SCHEDULE_LOOKBACK_DAYS') }} DAY)
    {% endif %}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__pathways') }}
),

dim_pathways AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'pathway_id']) }} AS key,
        feed_key,
        pathway_id,
        from_stop_id,
        to_stop_id,
        pathway_mode,
        is_bidirectional,
        length,
        traversal_time,
        stair_count,
        max_slope,
        min_width,
        signposted_as,
        reversed_signposted_as,
        base64_url,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_pathways
