{{
    config(
        materialized='view',
        tags=['tides_product'],
    )
}}

WITH source_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
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
)

SELECT * FROM tides_vehicle_locations
