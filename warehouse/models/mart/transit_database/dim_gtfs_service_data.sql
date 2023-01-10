{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_service_data_dim') }}
),

datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

services AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

dim_gtfs_service_data AS (
    SELECT
        dim.key,
        dim.name,
        services.key AS service_key,
        datasets.key AS gtfs_dataset_key,
        dim.customer_facing,
        dim.category,
        dim.agency_id,
        dim.network_id,
        dim.route_id,
        dim.fares_v2_status,
        (dim._is_current AND datasets._is_current AND services._is_current) AS _is_current,
        GREATEST(dim._valid_from, datasets._valid_from, services._valid_from) AS _valid_from,
        LEAST(dim._valid_to, datasets._valid_to, services._valid_to) AS _valid_to
    FROM dim
    LEFT JOIN datasets
        ON dim.gtfs_dataset_key = datasets.original_record_id
        AND dim._valid_from < datasets._valid_to
        AND dim._valid_to > datasets._valid_from
    LEFT JOIN services
        ON dim.service_key = services.original_record_id
        AND dim._valid_from < services._valid_to
        AND dim._valid_to > services._valid_from
)

SELECT * FROM dim_gtfs_service_data
