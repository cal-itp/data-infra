{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_stops AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_stops') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_stops') }}
),

dim_stops AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'stop_id']) }} AS key,
        base64_url,
        feed_key,

        stop_id,
        tts_stop_name,
        stop_lat,
        stop_lon,
        zone_id,
        parent_station,
        stop_code,
        stop_name,
        stop_desc,
        stop_url,
        location_type,
        stop_timezone,
        wheelchair_boarding,
        level_id,
        platform_code,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_stops
