{{
    config(
        materialized='view',
        tags=['tides_product'],
    )
}}

-- This model is a view. The TIDES export DAG queries it filtered by
-- `dt` + `base64_url`; that predicate prunes straight through to the
-- partitioned/clustered `fct_vehicle_locations` scan (verified: a single
-- agency-day prunes 1.19 TB -> 1.8 GB).
--
-- Dedup: upstream `key` is "almost unique" (documented unique_proportion
-- at_least 0.999). `key` is composed of base64_url + location_timestamp +
-- vehicle_id + ..., so those columns can't tie-break; `_extract_ts` (the
-- upstream extract timestamp) differs across duplicates, so pick the
-- most-recently-extracted row per key.
--
-- The window partitions by (key, dt, base64_url), not key alone, so that a
-- view consumer's `WHERE dt = .. AND base64_url = ..` can be pushed below the
-- window (BigQuery only pushes a filter past a window when the filter columns
-- are a subset of PARTITION BY). base64_url is already a component of `key`, so
-- adding it changes nothing; `dt` scopes the dedup to a single scrape-day,
-- which is the export grain -- the DAG reads one `dt` at a time.
WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY `key`, dt, base64_url
        ORDER BY _extract_ts DESC
    ) = 1
),

-- Pre-filter dim_provider_gtfs_data to the publication set: every organization
-- with the public-customer-facing or regional-subfeed fixed-route flag that is
-- NOT on the tides_publication_keys denylist (a LEFT JOIN anti-join). This
-- expands each published org to all of its current customer-facing VP feeds.
-- Persistent Airtable org IDs are stable across gtfs_dataset_key and feed-URL
-- rotations. Rolling out more agencies means deleting their denylist rows.
publication_dim_records AS (
    SELECT d.*
    FROM {{ ref('dim_provider_gtfs_data') }} AS d
    LEFT JOIN {{ ref('tides_publication_keys') }} AS excluded
        ON d.organization_source_record_id = excluded.organization_source_record_id
    WHERE d.public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND d.organization_source_record_id IS NOT NULL
      AND excluded.organization_source_record_id IS NULL
),

-- SCD Type 2 join: resolve the dim record valid at each VP row's
-- _extract_ts (not the current state).
filtered_vehicle_locations AS (
    SELECT
        vp.*,
        d.organization_source_record_id
    FROM source_vehicle_locations AS vp
    INNER JOIN publication_dim_records AS d
        ON d.vehicle_positions_gtfs_dataset_key = vp.gtfs_dataset_key
        AND vp._extract_ts BETWEEN d._valid_from AND d._valid_to
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

        -- Internal columns, dropped at export time. dt + base64_url drive the
        -- export DAG's pruned query; organization_source_record_id routes the
        -- output and keys tides_publication_feeds; gtfs_dataset_key joins feeds.
        vp.dt,
        vp.base64_url,
        vp.gtfs_dataset_key,
        vp.organization_source_record_id
    FROM filtered_vehicle_locations AS vp
)

SELECT * FROM tides_vehicle_locations
