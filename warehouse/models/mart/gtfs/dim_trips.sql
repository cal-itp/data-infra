{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time = '_feed_valid_from',
        batch_size = 'day',
        begin=var('GTFS_SCHEDULE_START'),
        lookback=var('DBT_ALL_MICROBATCH_LOOKBACK_DAYS'),
        partition_by={
            'field': '_feed_valid_from',
            'data_type': 'timestamp',
            'granularity': 'day',
        },
        full_refresh=false,
        cluster_by='feed_key'
    )
}}

WITH dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

stg AS ( --noqa: ST03
    SELECT * FROM {{ ref('stg_gtfs_schedule__trips') }}
),

make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds_microbatch(
        'dim_schedule_feeds',
        'stg',
    ) }}
),


dim_trips AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'trip_id']) }} AS _gtfs_key,
        base64_url,
        feed_key,
        route_id,
        service_id,
        trip_id,
        shape_id,
        trip_headsign,
        trip_short_name,
        direction_id,
        block_id,
        wheelchair_accessible,
        bikes_allowed,
        COUNT(*) OVER (PARTITION BY feed_key, trip_id) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_trips
