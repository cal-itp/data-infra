{{ config(materialized='view') }}

WITH observed AS (
    SELECT *
    FROM {{ ref('fct_observed_trips') }}
    -- Drop TU-only trips (no VP) so every row has a derivable vehicle_id.
    WHERE appeared_in_vp = TRUE
),

scheduled AS (
    SELECT
        trip_instance_key,
        route_id,
        route_type,
        direction_id,
        shape_id,
        block_id,
        feed_timezone,
        trip_first_departure_ts,
        trip_last_arrival_ts
    FROM {{ ref('fct_scheduled_trips') }}
),

vehicle_per_trip AS (
    SELECT
        service_date,
        trip_id_performed,
        APPROX_TOP_COUNT(vehicle_id, 1)[OFFSET(0)].value AS vehicle_id
    FROM {{ ref('fct_tides_vehicle_locations') }}
    WHERE vehicle_id IS NOT NULL
    GROUP BY 1, 2
),

-- Same shared-feed agency collapse as fct_tides_vehicle_locations.
public_subfeed_agencies AS (
    SELECT
        vehicle_positions_gtfs_dataset_key AS gtfs_dataset_key,
        organization_name,
        organization_ntd_id
    FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current = TRUE
      AND public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND vehicle_positions_gtfs_dataset_key IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY vehicle_positions_gtfs_dataset_key
        ORDER BY organization_name ASC
    ) = 1
),

tides_trips_performed AS (
    SELECT
        o.service_date,
        o.trip_id AS trip_id_performed,
        v.vehicle_id,

        -- trip_id_scheduled coarse: trip appeared in VP or TU implies a
        -- scheduled trip. A stricter test would require fct_scheduled_trips
        -- presence.
        o.trip_id AS trip_id_scheduled,

        s.route_id,
        s.route_type,
        CAST(NULL AS STRING) AS ntd_mode,
        CAST(NULL AS STRING) AS route_type_agency,
        s.shape_id,
        CAST(NULL AS STRING) AS pattern_id,
        s.direction_id,
        CAST(NULL AS STRING) AS operator_id,
        s.block_id,
        CAST(NULL AS STRING) AS trip_start_stop_id,
        CAST(NULL AS STRING) AS trip_end_stop_id,

        DATETIME(s.trip_first_departure_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS schedule_trip_start,
        DATETIME(s.trip_last_arrival_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS schedule_trip_end,
        DATETIME(o.vp_min_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS actual_trip_start,
        DATETIME(o.vp_max_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS actual_trip_end,

        -- Constant 'In service' since the model filters to VP-observed trips.
        'In service' AS trip_type,

        CASE
            WHEN o.tu_starting_schedule_relationship = 'SCHEDULED'   THEN 'Scheduled'
            WHEN o.tu_starting_schedule_relationship = 'ADDED'       THEN 'Added'
            WHEN o.tu_starting_schedule_relationship = 'CANCELED'    THEN 'Canceled'
            WHEN o.tu_starting_schedule_relationship = 'UNSCHEDULED' THEN 'Unscheduled'
            WHEN o.tu_starting_schedule_relationship = 'DUPLICATED'  THEN 'Duplicated'
        END AS schedule_relationship,

        -- Internal columns retained for partitioning and downstream joins;
        -- dropped at export.
        o.vp_base64_url AS base64_url,
        o.vp_gtfs_dataset_key AS gtfs_dataset_key,
        a.organization_name,
        a.organization_ntd_id
    FROM observed o
    INNER JOIN public_subfeed_agencies a
        ON o.vp_gtfs_dataset_key = a.gtfs_dataset_key
    LEFT JOIN scheduled s
        ON s.trip_instance_key = o.trip_instance_key
    LEFT JOIN vehicle_per_trip v
        ON v.service_date = o.service_date
       AND v.trip_id_performed = o.trip_id
),

-- TIDES requires (service_date, trip_id_performed) unique. fct_observed_trips
-- can have multiple rows per PK when the same trip appears in multiple feeds;
-- pick one canonical row by latest observed VP activity.
deduped AS (
    SELECT *
    FROM tides_trips_performed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY service_date, trip_id_performed
        ORDER BY actual_trip_end DESC NULLS LAST,
                 actual_trip_start ASC NULLS LAST,
                 base64_url ASC
    ) = 1
)

SELECT * FROM deduped
