{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time = 'dt',
        batch_size = 'day',
        begin=var('GTFS_RT_START'),
        lookback=var('DBT_ALL_INCREMENTAL_LOOKBACK_DAYS'),
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        full_refresh=false,
        cluster_by='base64_url',
        on_schema_change='append_new_columns',
        tags=['tides_product'],
    )
}}

-- Upstream `key` is "almost unique" (documented unique_proportion at_least
-- 0.999); TIDES requires location_ping_id strictly unique. `key` is composed
-- of base64_url + location_timestamp + vehicle_id + ..., so those columns are
-- all constant within a duplicate set and can't tie-break. `_extract_ts` is
-- the upstream extract timestamp and differs across the duplicates, so pick
-- the most-recently-extracted row per key.
WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY `key`
        ORDER BY _extract_ts DESC
    ) = 1
),

-- Filter to feeds tagged public-customer-facing or regional-subfeed
-- fixed-route. Org info isn't part of the TIDES spec and isn't carried
-- through; org metadata for the publish flow lives separately.
public_subfeed_keys AS (
    SELECT DISTINCT vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current = TRUE
      AND public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND vehicle_positions_gtfs_dataset_key IS NOT NULL
),

-- Narrows the public-subfeed set to the MVP publication list (Hermosa Beach
-- traversing operators). Additive on top of the public-subfeed filter above.
publication_keys AS (
    SELECT gtfs_dataset_key
    FROM {{ ref('tides_publication_keys') }}
),

tides_vehicle_locations AS (
    SELECT
        vp.key AS location_ping_id,
        vp.service_date,
        DATETIME(vp.location_timestamp, vp.schedule_feed_timezone) AS event_timestamp,

        vp.trip_id AS trip_id_performed,
        -- trip_id_scheduled left NULL for MVP; deriving requires a reliable
        -- join to fct_scheduled_trips on schedule_base64_url + trip_start_time.
        CAST(NULL AS STRING) AS trip_id_scheduled,

        -- TIDES requires trip_stop_sequence >= 1. GTFS-RT current_stop_sequence
        -- can be 0 when approaching the first stop; NULL it out instead of
        -- emitting a spec-violating value.
        CASE WHEN vp.current_stop_sequence >= 1 THEN vp.current_stop_sequence END
            AS trip_stop_sequence,
        CAST(NULL AS INT64) AS scheduled_stop_sequence,

        vp.vehicle_id,
        CAST(NULL AS STRING) AS device_id,
        CAST(NULL AS STRING) AS pattern_id,
        vp.stop_id,

        CASE vp.current_status
            WHEN 'INCOMING_AT'   THEN 'Incoming at'
            WHEN 'STOPPED_AT'    THEN 'Stopped at'
            WHEN 'IN_TRANSIT_TO' THEN 'In transit to'
        END AS current_status,

        -- null out values outside TIDES schema bounds so spec validation passes
        -- upstream RT data quality is monitored separately by the TDQ team
        CASE
            WHEN vp.position_latitude BETWEEN -90 AND 90
            THEN vp.position_latitude
        END AS latitude,
        CASE
            WHEN vp.position_longitude BETWEEN -180 AND 180
            THEN vp.position_longitude
        END AS longitude,

        CAST(NULL AS STRING) AS gps_quality,

        CASE
            WHEN vp.position_bearing BETWEEN 0 AND 360
            THEN vp.position_bearing
        END AS heading,

        CASE WHEN vp.position_speed >= 0 THEN vp.position_speed END AS speed,
        CASE WHEN vp.position_odometer >= 0 THEN vp.position_odometer END AS odometer,

        CAST(NULL AS INT64) AS schedule_deviation,
        CAST(NULL AS INT64) AS headway_deviation,

        -- fct_vehicle_locations drops NULL trip_id upstream, so this is
        -- effectively constant 'In service'. Expression kept for future
        -- expansion to the deadhead / layover / pull-in / pull-out cases.
        CASE WHEN vp.trip_id IS NOT NULL THEN 'In service' END AS trip_type,

        -- TIDES schedule_relationship at vehicle_locations is stop-level
        -- (Scheduled / Skipped / Added / Missing); GTFS-RT carries trip-level.
        -- Leaving NULL pending https://github.com/TIDES-transit/TIDES/issues/252.
        CAST(NULL AS STRING) AS schedule_relationship,

        -- Internal columns retained for partitioning and the feed-key join;
        -- dropped at export time.
        vp.dt,
        vp.base64_url,
        vp.gtfs_dataset_key
    FROM source_vehicle_locations AS vp
    INNER JOIN public_subfeed_keys USING (gtfs_dataset_key)
    INNER JOIN publication_keys USING (gtfs_dataset_key)
)

SELECT * FROM tides_vehicle_locations
