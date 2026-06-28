{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_expiration_days=15,
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
    -- now partitioned by service_date, so filter on it directly to prune partitions
    WHERE service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }}
      AND vehicle_id IS NOT NULL
    GROUP BY 1, 2
),

publication_dim_records AS (
    SELECT d.*
    FROM {{ ref('dim_provider_gtfs_data') }} AS d
    LEFT JOIN {{ ref('tides_publication_keys') }} AS excluded
        ON d.organization_source_record_id = excluded.organization_source_record_id
    WHERE d.public_customer_facing_or_regional_subfeed_fixed_route = TRUE
      AND d.organization_source_record_id IS NOT NULL
      AND excluded.organization_source_record_id IS NULL
),

filtered_observed AS (
    SELECT o.*,
           d.organization_source_record_id
    FROM observed AS o
    INNER JOIN publication_dim_records AS d
        ON d.vehicle_positions_gtfs_dataset_key = o.vp_gtfs_dataset_key
        AND o.vp_min_ts BETWEEN d._valid_from AND d._valid_to
),

tides_trips_performed_dup AS (
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
        s.shape_id,
        s.direction_id,
        s.block_id,
        DATETIME(s.trip_first_departure_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS schedule_trip_start,
        DATETIME(s.trip_last_arrival_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS schedule_trip_end,
        DATETIME(o.vp_min_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS actual_trip_start,
        DATETIME(o.vp_max_ts, COALESCE(s.feed_timezone, 'America/Los_Angeles')) AS actual_trip_end,
        'In service' AS trip_type,
        INITCAP(o.tu_starting_schedule_relationship) AS schedule_relationship,
        o.vp_base64_url AS base64_url,
        o.vp_gtfs_dataset_key AS gtfs_dataset_key,
        o.organization_source_record_id
    FROM filtered_observed o
    LEFT JOIN scheduled s
        ON s.trip_instance_key = o.trip_instance_key
    LEFT JOIN vehicle_per_trip v
        ON v.service_date = o.service_date
       AND v.trip_id_performed = o.trip_id
),

fct_tides_trips_performed AS (
    SELECT *
    FROM tides_trips_performed_dup
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY service_date, trip_id_performed, gtfs_dataset_key
        ORDER BY actual_trip_end DESC NULLS LAST,
                 actual_trip_start ASC NULLS LAST
    ) = 1
)

SELECT * FROM fct_tides_trips_performed
