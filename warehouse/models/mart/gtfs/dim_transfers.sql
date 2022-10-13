{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_transfers AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_transfers') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_transfers') }}
),

dim_transfers AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'from_stop_id', 'to_stop_id', 'from_trip_id', 'to_trip_id', 'from_route_id',' to_route_id']) }} AS key,
        feed_key,
        gtfs_dataset_key,
        from_stop_id,
        to_stop_id,
        transfer_type,
        from_route_id,
        to_route_id,
        from_trip_id,
        to_trip_id,
        min_transfer_time,
        base64_url,
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_transfers
