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

WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
    -- fct_vehicle_locations is partitioned by dt (UTC); we partition by
    -- service_date (local). A service_date appears in dt = service_date and
    -- dt = service_date + 1, so read one extra trailing UTC day to fully cover
    -- the local window, then trim back to the exact service_date range below.
    WHERE dt
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }} + 1
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY `key`, service_date, base64_url
        ORDER BY _extract_ts DESC
    ) = 1
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
        vp.current_stop_sequence AS trip_stop_sequence,
        vp.vehicle_id,
        vp.stop_id,
        REPLACE(INITCAP(vp.current_status, ''), '_', ' ') AS current_status,
        vp.position_latitude AS latitude,
        vp.position_longitude AS longitude,
        vp.position_bearing AS heading,
        vp.position_speed AS speed,
        vp.position_odometer AS odometer,
        IF(vp.trip_id IS NOT NULL, 'In service', NULL) AS trip_type,
        vp.dt,
        vp.base64_url,
        vp.gtfs_dataset_key,
        vp.organization_source_record_id
    FROM filtered_vehicle_locations AS vp
    -- Trim the dt+1 read back to the exact service_date partition window so
    -- insert_overwrite only rewrites partitions it has fully recomputed.
    WHERE vp.service_date
        BETWEEN {{ ranged_incremental_min_date(default_lookback=var("DBT_ALL_INCREMENTAL_LOOKBACK_DAYS"), data_earliest_start=var("TIDES_PRODUCT_START")) }}
            AND {{ ranged_incremental_max_date() }}
)

SELECT * FROM tides_vehicle_locations
