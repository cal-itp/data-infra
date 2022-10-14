{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__calendar AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__calendar') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__calendar') }}
),

dim_calendar AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'service_id']) }} AS key,
        feed_key,

        service_id,
        monday,
        tuesday,
        wednesday,
        thursday,
        friday,
        saturday,
        sunday,
        start_date,
        end_date,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_calendar
