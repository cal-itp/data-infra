{{
    config(
        materialized='incremental',
        incremental_strategy='microbatch',
        event_time='dt',
        batch_size='day',
        begin=var('GTFS_RT_START'),
        lookback=var('DBT_ALL_MICROBATCH_LOOKBACK_DAYS'),
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        full_refresh=false,
        cluster_by=['dt', 'base64_url'],
        on_schema_change='append_new_columns'
    )
}}

WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
),

-- dim_provider_gtfs_data fans out: a single vehicle_positions feed can be
-- associated with multiple service or organization rows (govcbus.com is shared
-- by 7 cities; the SD MTS feed is shared with the airport). Collapse to one
-- row per VP feed key, picking the lex-smallest organization_name for
-- determinism, so the join below doesn't multiply ping rows.
public_subfeed_agencies AS (
    SELECT
        vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key,
        ANY_VALUE(organization_name HAVING MIN organization_name) AS organization_name,
        ANY_VALUE(organization_ntd_id HAVING MIN organization_name) AS organization_ntd_id
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current = TRUE
      AND public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND vehicle_positions_gtfs_dataset_key IS NOT NULL
    GROUP BY 1
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
        -- Leaving NULL pending TIDES spec clarification (TIDES issue #252).
        CAST(NULL AS STRING) AS schedule_relationship,

        -- Internal columns retained for partitioning and the agency join;
        -- dropped at export time.
        vp.dt,
        vp.base64_url,
        vp.gtfs_dataset_key,
        agencies.organization_name,
        agencies.organization_ntd_id
    FROM source_vehicle_locations AS vp
    INNER JOIN public_subfeed_agencies AS agencies
        USING (gtfs_dataset_key)
),

-- TIDES requires location_ping_id strictly unique; the upstream key is
-- "almost unique" (unique_proportion at_least 0.999), so pick one canonical
-- row per id (most recent ping, then lex-smallest feed for determinism).
deduped AS (
    SELECT *
    FROM tides_vehicle_locations
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY location_ping_id
        ORDER BY event_timestamp DESC, base64_url ASC
    ) = 1
)

SELECT * FROM deduped
