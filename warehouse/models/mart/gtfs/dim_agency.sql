{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__agency AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__agency') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__agency') }}
),

dim_agency AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'agency_id']) }} AS key,
        feed_key,

        agency_id,
        agency_name,
        agency_url,
        agency_timezone,
        agency_lang,
        agency_phone,
        agency_fare_url,
        agency_email,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_agency
