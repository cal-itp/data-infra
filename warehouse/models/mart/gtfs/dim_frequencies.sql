{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__frequencies AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__frequencies') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__frequencies') }}
),

dim_frequencies AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'trip_id', 'start_time']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        trip_id,
        start_time,
        end_time,
        headway_secs,
        exact_times,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_frequencies
