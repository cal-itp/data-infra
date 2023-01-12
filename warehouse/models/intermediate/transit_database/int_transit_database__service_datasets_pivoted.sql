{{ config(materialized='table') }}

WITH dim_gtfs_service_data AS (
    SELECT *
    FROM {{ ref('dim_gtfs_service_data') }}
),

bridge_schedule_dataset_for_validation AS (
    SELECT *
    FROM {{ ref('bridge_schedule_dataset_for_validation') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

datasets_services_joined AS (
    SELECT
        service_key,
        datasets.key AS gtfs_dataset_key,
        COALESCE(
            customer_facing,
            category = "primary") AS customer_facing,
        datasets.type,
        service_data._is_current AS _is_current,
        service_data._valid_from,
        service_data._valid_to
    FROM dim_gtfs_service_data AS service_data
    -- because dim_gtfs_service_data is already fully versioned (already accounts for dataset versioning)
    -- we don't need SCD date logic a second time here
    INNER JOIN dim_gtfs_datasets AS datasets
        ON service_data.gtfs_dataset_key = datasets.key
),

associated_schedule AS (
    SELECT
        service_key,
        dataset_service.gtfs_dataset_key,
        -- TODO: this logic will fail if we want to use MTC 511 regional alerts feed with
        -- all subfeeds because the subfeeds are not listed to be used for validation of the alerts feed
        -- easiest fix (very manual) is probably just to join the alerts feed in later after the quartets are constructed
        CASE
            WHEN type = "schedule" THEN dataset_service.gtfs_dataset_key
            ELSE bridge.schedule_to_use_for_rt_validation_gtfs_dataset_key
        END AS associated_gtfs_schedule_gtfs_dataset_key,
        customer_facing,
        type,
        GREATEST(dataset_service._valid_from, COALESCE(bridge._valid_from, '1900-01-01')) AS _valid_from,
        LEAST(dataset_service._valid_to, COALESCE(bridge._valid_to, '2099-01-01')) AS _valid_to
    FROM datasets_services_joined AS dataset_service
    LEFT JOIN combined_bridge AS bridge
        ON dataset_service.gtfs_dataset_key = bridge.gtfs_dataset_key
        AND dataset_service._valid_from < bridge._valid_to
        AND dataset_service._valid_to > bridge._valid_from
),

-- service_schedule_spine AS (
--     SELECT DISTINCT
--         service_key,
--         associated_gtfs_schedule_gtfs_dataset_key,
--         customer_facing,
--     FROM associated_schedule
-- ),

-- join_schedule AS (
--     SELECT
--         service_key,
--         spine.associated_gtfs_schedule_gtfs_dataset_key,
--         datasets.key AS schedule_key,
--         datasets._valid_from,
--         datasets._valid_to
--     FROM service_schedule_spine AS spine
--     LEFT JOIN associated_schedule AS datasets
--         ON spine.service_key = datasets.service_key
--         AND spine.associated_gtfs_schedule_gtfs_dataset_key = datasets.associated_gtfs_schedule_gtfs_dataset_key
--         AND spine.customer_facing = datasets.customer_facing
--         AND datasets.type = "schedule"
-- ),

-- join_alerts AS (
--     SELECT
--         service_key,
--         spine.associated_gtfs_schedule_gtfs_dataset_key,
--         schedule_key,
--         datasets.key AS service_alerts_key,
--         COALESCE(
--             GREATEST(spine._valid_from,
--                     datasets._valid_from)
--             , spine._valid_from,
--             , datasets._valid_from) AS _valid_from,
--         LEAST(dataset_service._valid_to, COALESCE(bridge._valid_to, '2099-01-01')) AS _valid_to
--     FROM join_schedule AS spine
--     LEFT JOIN associated_schedule AS datasets
--         ON spine.service_key = datasets.service_key
--         AND spine.associated_gtfs_schedule_gtfs_dataset_key = datasets.associated_gtfs_schedule_gtfs_dataset_key
--         AND spine.customer_facing = datasets.customer_facing
--         AND datasets.type = "service_alerts"
-- ),

pivoted AS (
    SELECT *
    FROM associated_schedule
    PIVOT(
        STRING_AGG(gtfs_dataset_key) AS gtfs_dataset_key
        FOR type IN ('schedule', 'service_alerts', 'trip_updates', 'vehicle_positions')
    )
),

int_transit_database__service_datasets_pivoted AS (
    SELECT
        dim_gtfs_service_data.key AS gtfs_service_data_key,
        pivoted.service_key,
        dim_gtfs_service_data.customer_facing,
        dim_gtfs_service_data.agency_id,
        dim_gtfs_service_data.network_id,
        dim_gtfs_service_data.route_id,
        pivoted.associated_gtfs_schedule_gtfs_dataset_key,
        pivoted.gtfs_dataset_key_schedule,
        pivoted.gtfs_dataset_key_service_alerts,
        pivoted.gtfs_dataset_key_trip_updates,
        pivoted.gtfs_dataset_key_vehicle_positions,
        (pivoted._is_current AND COALESCE(dim_gtfs_service_data._is_current, TRUE)) AS _is_current,
        GREATEST(pivoted._valid_from, COALESCE(dim_gtfs_service_data._valid_from, '1900-01-01')) AS _valid_from,
        LEAST(pivoted._valid_to, COALESCE(dim_gtfs_service_data._valid_to, '2099-01-01')) AS _valid_to
    FROM pivoted
    LEFT JOIN dim_gtfs_service_data
        ON pivoted.gtfs_dataset_key_schedule = dim_gtfs_service_data.gtfs_dataset_key
        AND pivoted.service_key = dim_gtfs_service_data.service_key
        AND pivoted._valid_from < dim_gtfs_service_data._valid_to
        AND pivoted._valid_to > dim_gtfs_service_data._valid_from
)

SELECT * FROM int_transit_database__service_datasets_pivoted
