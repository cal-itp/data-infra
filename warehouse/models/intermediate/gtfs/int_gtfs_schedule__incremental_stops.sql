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

stg_gtfs_schedule__stops AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__stops') }}
    {% if is_incremental() %}
    WHERE _dt >= EXTRACT(DATE FROM TIMESTAMP('{{ max_ts }}'))
    {% endif %}
),

int_gtfs_schedule__incremental_stops AS (
    -- select distinct because there is at least one feed that
    -- has entire duplicates (all values identical)
    SELECT DISTINCT
        t1.base64_url,
        t1.ts,
        t1.stop_id,
        t1.tts_stop_name,
        t1.stop_lat,
        t1.stop_lon,
        t1.zone_id,
        t1.parent_station,
        t1.stop_code,
        t1.stop_name,
        t1.stop_desc,
        t1.stop_url,
        t1.location_type,
        t1.stop_timezone,
        t1.wheelchair_boarding,
        t1.level_id,
        t1.platform_code,
        CURRENT_TIMESTAMP() AS _inserted_at
    FROM stg_gtfs_schedule__stops t1
    INNER JOIN dim_schedule_feeds t2
        ON t1.base64_url = t2.base64_url
        AND t1.ts = t2._valid_from
)

SELECT *
FROM int_gtfs_schedule__incremental_stops
