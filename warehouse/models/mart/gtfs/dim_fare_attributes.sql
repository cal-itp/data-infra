{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__fare_attributes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__fare_attributes') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__fare_attributes') }}
),

dim_fare_attributes AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'fare_id']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        fare_id,
        price,
        currency_type,
        payment_method,
        transfers,
        agency_id,
        transfer_duration,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_fare_attributes
