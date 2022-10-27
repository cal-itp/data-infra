{{ config(materialized='incremental') }}

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

stg_gtfs_schedule__trips AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__trips') }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT (DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% endif %}
),

int_gtfs_schedule__incremental_trips AS (
    -- select distinct because there is at least one feed that
    SELECT DISTINCT
        t1.base64_url,
        t1.ts,
        t1.route_id,
        t1.service_id,
        t1.trip_id,
        t1.shape_id,
        t1.trip_headsign,
        t1.trip_short_name,
        t1.direction_id,
        t1.block_id,
        t1.wheelchair_accessible,
        t1.bikes_allowed,
        CURRENT_TIMESTAMP() AS _inserted_at
    FROM stg_gtfs_schedule__trips t1
    INNER JOIN dim_schedule_feeds t2
        ON t1.base64_url = t2.base64_url
        AND t1.ts = t2._valid_from
)

SELECT *
FROM int_gtfs_schedule__incremental_trips
