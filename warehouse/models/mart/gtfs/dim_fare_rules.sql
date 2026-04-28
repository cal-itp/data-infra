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
    SELECT * FROM {{ ref('stg_gtfs_schedule__fare_rules') }}
),

make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds_microbatch(
        'dim_schedule_feeds',
        'stg',
    ) }}
),


-- so we can reference twice
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['fare_id', 'route_id', 'origin_id', 'destination_id', 'contains_id']) }} AS fare_rule_identifier,
    FROM make_dim
),

dim_fare_rules AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_rule_identifier']) }} AS _gtfs_key,
        feed_key,
        fare_id,
        route_id,
        origin_id,
        destination_id,
        contains_id,
        base64_url,
        COUNT(*) OVER (PARTITION BY feed_key, fare_rule_identifier) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
)

SELECT * FROM dim_fare_rules
