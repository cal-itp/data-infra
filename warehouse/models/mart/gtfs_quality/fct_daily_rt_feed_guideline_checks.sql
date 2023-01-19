{{ config(materialized='table') }}

WITH

unioned AS (
    {{ dbt_utils.union_relations(
        relations=[
            ref('int_gtfs_quality__no_rt_validation_errors'),
            ref('int_gtfs_quality__rt_feeds_present'),
            ref('int_gtfs_quality__trip_id_alignment'),
            ref('int_gtfs_quality__rt_https'),
            ref('int_gtfs_quality__rt_20sec_vp'),
            ref('int_gtfs_quality__rt_20sec_tu'),
            ref('int_gtfs_quality__rt_protobuf_error'),
            ref('int_gtfs_quality__no_stale_vehicle_positions'),
            ref('int_gtfs_quality__no_stale_service_alerts'),
            ref('int_gtfs_quality__no_stale_trip_updates'),
            ref('int_gtfs_quality__feed_aggregator_rt'),
        ],
    ) }}
),

fct_daily_rt_feed_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key(['date', 'base64_url', 'check']) }} AS key,
        *
    FROM unioned
)

SELECT * FROM fct_daily_rt_feed_guideline_checks
