{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['service_date', 'base64_url'],
        on_schema_change='append_new_columns',
        tags=['tides_product'],
    )
}}

WITH observed AS (
    SELECT *
    FROM {{ ref('fct_observed_trips') }}
    -- Drop TU-only trips (no VP) so every row has a derivable vehicle_id.
    WHERE appeared_in_vp = TRUE
      AND service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }}
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
    WHERE service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }}
),

vehicle_per_trip AS (
    SELECT
        service_date,
        trip_id_performed,
        APPROX_TOP_COUNT(vehicle_id, 1)[OFFSET(0)].value AS vehicle_id
    FROM {{ ref('fct_tides_vehicle_locations') }}
    -- we load this by dt rather than service date
    -- this is ok for the min date because t-X days for service date will be fully covered by t-X days for dt
    -- add one to the incremental max date because we need to get one extra UTC dt to ensure overlap with service date
    WHERE dt
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }} + 1
      AND vehicle_id IS NOT NULL
    GROUP BY 1, 2
),

-- Pre-filter dim_provider_gtfs_data to the publication-set organizations
-- (persistent Airtable org IDs, stable across upstream gtfs_dataset_key and
-- feed-URL rotations) with the public-customer-facing or regional-subfeed
-- fixed-route flag. Joining on the organization expands each allowlisted
-- agency to all of its current customer-facing VP feeds.
publication_dim_records AS (
    SELECT d.*
    FROM {{ ref('dim_provider_gtfs_data') }} AS d
    INNER JOIN {{ ref('tides_publication_keys') }}
        USING (organization_source_record_id)
    WHERE d.public_customer_facing_or_regional_subfeed_fixed_route = TRUE
),

-- SCD Type 2 join: resolve the dim record valid at vp_min_ts (the earliest
-- VP timestamp for the trip), not the current state.
filtered_observed AS (
    SELECT o.*
    FROM observed AS o
    INNER JOIN publication_dim_records AS d
        ON d.vehicle_positions_gtfs_dataset_key = o.vp_gtfs_dataset_key
        AND o.vp_min_ts BETWEEN d._valid_from AND d._valid_to
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
        o.vp_gtfs_dataset_key AS gtfs_dataset_key
    FROM filtered_observed o
    LEFT JOIN scheduled s
        ON s.trip_instance_key = o.trip_instance_key
    LEFT JOIN vehicle_per_trip v
        ON v.service_date = o.service_date
       AND v.trip_id_performed = o.trip_id
),

-- TIDES IDs are only unique within feed; partition the dedup by feed identity
-- so trips that share trip_id_performed across different feeds both survive.
deduped AS (
    SELECT *
    FROM tides_trips_performed
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY service_date, trip_id_performed, gtfs_dataset_key
        ORDER BY actual_trip_end DESC NULLS LAST,
                 actual_trip_start ASC NULLS LAST
    ) = 1
)

SELECT * FROM deduped
