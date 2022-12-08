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

stg_gtfs_schedule__stop_times AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__stop_times') }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT (DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% endif %}
),

int_gtfs_schedule__incremental_stop_times AS (
    SELECT
        stop_times.base64_url,
        stop_times.ts,
        stop_times.trip_id,
        stop_times.stop_id,
        stop_times.stop_sequence,
        stop_times.arrival_time,
        stop_times.departure_time,
        stop_times.stop_headsign,
        stop_times.pickup_type,
        stop_times.drop_off_type,
        stop_times.continuous_pickup,
        stop_times.continuous_drop_off,
        stop_times.shape_dist_traveled,
        stop_times.timepoint,
        CURRENT_TIMESTAMP() AS _inserted_at
    FROM stg_gtfs_schedule__stop_times stop_times
    INNER JOIN dim_schedule_feeds feeds
        ON stop_times.base64_url = feeds.base64_url
        AND stop_times.ts = feeds._valid_from
)

SELECT *
FROM int_gtfs_schedule__incremental_stop_times
