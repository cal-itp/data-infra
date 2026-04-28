{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time = '_feed_valid_from',
        batch_size = 'day',
        begin=var('GTFS_SCHEDULE_START'),
        lookback=var('DBT_ALL_INCREMENTAL_LOOKBACK_DAYS'),
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
    SELECT * FROM {{ ref('stg_gtfs_schedule__frequencies') }}
),

make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds_microbatch(
        'dim_schedule_feeds',
        'stg',
    ) }}
),


make_intervals AS(
    SELECT
        *,
        {{ gtfs_time_string_to_interval('start_time') }} AS start_time_interval,
        {{ gtfs_time_string_to_interval('end_time') }} AS end_time_interval,
    FROM make_dim
),

dim_frequencies AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'trip_id', 'start_time']) }} AS _gtfs_key,
        feed_key,
        trip_id,
        start_time,
        end_time,
        start_time_interval,
        end_time_interval,
        {{ gtfs_interval_to_seconds('start_time_interval') }} AS start_time_sec,
        {{ gtfs_interval_to_seconds('end_time_interval') }} AS end_time_sec,
        headway_secs,
        exact_times,
        base64_url,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone
    FROM make_intervals
)

SELECT * FROM dim_frequencies
