{{ config(materialized='incremental') }}

-- BigQuery does not do partition elimination when using a subquery: https://stackoverflow.com/questions/54135893/using-subquery-for-partitiontime-in-bigquery-does-not-limit-cost
-- save max timestamp in a variable instead so it can be referenced in incremental logic and still use partition elimination
{% if is_incremental() %}
    {% set timestamps = dbt_utils.get_column_values(table=this, column='ts', order_by = 'ts DESC', max_records = 1) %}
    {% set max_ts = timestamps[0] %}
{% endif %}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
    {% if is_incremental() %}
    WHERE _valid_from > '{{ max_ts }}'
    {% endif %}
),

stg_gtfs_schedule__shapes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__shapes') }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% endif %}
),

int_gtfs_schedule__incremental_shapes AS (
    SELECT
        t1.shape_id,
        t1.shape_pt_lat,
        t1.shape_pt_lon,
        t1.shape_pt_sequence,
        t1.shape_dist_traveled,
        t1.base64_url,
        CURRENT_TIMESTAMP() AS _inserted_at
    FROM stg_gtfs_schedule__shapes t1
    INNER JOIN dim_schedule_feeds t2
        ON t1.base64_url = t2.base64_url
        AND t1.ts = t2._valid_from
)

SELECT *
FROM int_gtfs_schedule__incremental_shapes
