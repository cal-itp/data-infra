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

-- TIDES vehicle_locations conformant view of Cal-ITP's GTFS-RT vehicle positions.
-- TIDES (Transit Integrated Data Exchange Specification) defines an open transit
-- data schema for sharing operational data between agencies and external developers.
-- This model reshapes fct_vehicle_locations into TIDES vehicle_locations shape and
-- restricts to public, customer-facing fixed-route feeds via dim_provider_gtfs_data.
-- Closes #4837. See https://tides-transit.org/main/

WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
),

-- Filter to public, customer-facing or regional-subfeed fixed-route feeds.
-- This is the default agency opt-in surface per issue #4837. Hermosa Beach
-- and other small operators are included via the regional subfeed flag.
-- The opt-in mechanism may eventually move to a dedicated TIDES export flag
-- on dim_provider_gtfs_data; for MVP we inherit the existing customer-facing flag.
--
-- dim_provider_gtfs_data fans out: a single vehicle_positions feed can be
-- associated with multiple service or organization rows. We collapse to one
-- row per VP feed key to prevent duplicate vehicle position pings in the
-- TIDES export. Picks the lexicographically smallest organization_name when
-- there are multiple (deterministic; the choice rarely matters because most
-- fan-out is service-level under the same operator).
public_subfeed_agencies AS (
    SELECT
        vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key,
        ANY_VALUE(organization_name HAVING MIN organization_name) AS organization_name,
        ANY_VALUE(organization_ntd_id HAVING MIN organization_name) AS organization_ntd_id
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current = TRUE
      AND public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND vehicle_positions_gtfs_dataset_key IS NOT NULL
    GROUP BY vehicle_positions_gtfs_dataset_key
),

tides_vehicle_locations AS (
    SELECT
        -- TIDES required fields
        vp.key AS location_ping_id,
        vp.service_date,
        -- TIDES expects datetime; Cal-ITP location_timestamp is TIMESTAMP (UTC).
        -- Cast to DATETIME in agency timezone for TIDES conformance.
        DATETIME(vp.location_timestamp, vp.schedule_feed_timezone) AS event_timestamp,

        -- Trip linkage
        vp.trip_id AS trip_id_performed,
        -- trip_id_scheduled left NULL for MVP. Deriving requires a reliable
        -- join to fct_scheduled_trips which depends on schedule_base64_url
        -- and trip_start_time alignment. Will be added in a follow-up PR.
        CAST(NULL AS STRING) AS trip_id_scheduled,

        -- Stop sequence: TIDES trip_stop_sequence is the actual order of stops
        -- visited; GTFS-RT current_stop_sequence is the scheduled order the vehicle
        -- is approaching. These are not strictly equivalent but match in the
        -- common in-service case. Documented as a known semantic gap; precise
        -- mapping requires the future stop_visits table.
        --
        -- TIDES requires trip_stop_sequence >= 1. GTFS-RT current_stop_sequence
        -- can be 0 when a vehicle is approaching the first stop (sequence 0
        -- in GTFS Schedule indexing). NULL out the 0 case to satisfy the TIDES
        -- minimum constraint rather than emit a spec-violating value.
        CASE WHEN vp.current_stop_sequence >= 1 THEN vp.current_stop_sequence END
            AS trip_stop_sequence,
        CAST(NULL AS INT64) AS scheduled_stop_sequence,

        vp.vehicle_id,
        CAST(NULL AS STRING) AS device_id,
        CAST(NULL AS STRING) AS pattern_id,
        vp.stop_id,

        -- Map GTFS-RT current_status enum to TIDES casing.
        CASE vp.current_status
            WHEN 'INCOMING_AT'   THEN 'Incoming at'
            WHEN 'STOPPED_AT'    THEN 'Stopped at'
            WHEN 'IN_TRANSIT_TO' THEN 'In transit to'
        END AS current_status,

        -- Spatial: enforce TIDES bounds (-90..90 lat, -180..180 lon).
        -- BigQuery-invalid lats are stored upstream but null out the geo here.
        CASE
            WHEN vp.position_latitude BETWEEN -90 AND 90
            THEN vp.position_latitude
        END AS latitude,
        CASE
            WHEN vp.position_longitude BETWEEN -180 AND 180
            THEN vp.position_longitude
        END AS longitude,

        CAST(NULL AS STRING) AS gps_quality,

        -- Bearing must be 0..360 per TIDES; null out invalid values rather than fail.
        CASE
            WHEN vp.position_bearing BETWEEN 0 AND 360
            THEN vp.position_bearing
        END AS heading,

        -- Speed must be >= 0 per TIDES; null out negatives (sometimes seen in raw RT).
        CASE WHEN vp.position_speed >= 0 THEN vp.position_speed END AS speed,
        CASE WHEN vp.position_odometer >= 0 THEN vp.position_odometer END AS odometer,

        CAST(NULL AS INT64) AS schedule_deviation,
        CAST(NULL AS INT64) AS headway_deviation,

        -- Coarse two-value trip_type. Cal-ITP's fct_vehicle_locations drops NULL
        -- trip_id rows upstream, so this is effectively constant 'In service' for
        -- now. Kept as an expression for clarity and future expansion.
        CASE WHEN vp.trip_id IS NOT NULL THEN 'In service' END AS trip_type,

        -- TIDES vehicle_locations.schedule_relationship enum is stop-level
        -- (Scheduled / Skipped / Added / Missing). GTFS-RT trip_schedule_relationship
        -- is trip-level. Leaving NULL pending TIDES spec clarification (see TIDES
        -- issue #252 / PR #251).
        CAST(NULL AS STRING) AS schedule_relationship,

        -- Cal-ITP-internal columns retained for joining and incremental partitioning.
        -- These are NOT part of the TIDES vehicle_locations schema; they are
        -- dropped at export time when files land in the public bucket.
        vp.dt,
        vp.base64_url,
        vp.gtfs_dataset_key,
        agencies.organization_name,
        agencies.organization_ntd_id
    FROM source_vehicle_locations AS vp
    INNER JOIN public_subfeed_agencies AS agencies
        USING (gtfs_dataset_key)
),

-- Defensive final dedup. The upstream fct_vehicle_locations.key is documented
-- as "almost unique" (unique_proportion at_least 0.999), so a small fraction
-- of rows can share location_ping_id even after the agency-fan-out fix above.
-- TIDES requires location_ping_id to be strictly unique. This QUALIFY picks
-- one canonical row per id, ordered by event_timestamp DESC then base64_url
-- to favor the most recent observation from the lexicographically smallest
-- feed identifier (deterministic).
deduped AS (
    SELECT *
    FROM tides_vehicle_locations
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY location_ping_id
        ORDER BY event_timestamp DESC, base64_url
    ) = 1
)

SELECT * FROM deduped
