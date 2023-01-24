{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__gtfs_service_data',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['fares_v2_status']
        ) }}
),

datasets AS (
    SELECT *
    FROM {{ ref('int_transit_database__gtfs_datasets_dim') }}
),

services AS (
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

services_join AS (
    SELECT
        dim.name,
        services.key AS service_key,
        services.name AS service_name,
        services._valid_from AS service_valid_from,
        services._valid_to AS service_valid_to,
        gtfs_dataset_key,
        COALESCE(
            customer_facing,
            category = "primary") AS customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        dim.fares_v2_status,
        id AS source_record_id,
        dim.manual_check__fixed_route_completeness,
        dim.manual_check__demand_response_completeness,
        id AS original_record_id,
        dim._valid_from AS rel_valid_from,
        dim._valid_to AS rel_valid_to,
        (dim._is_current AND services._is_current) AS _is_current,
        GREATEST(dim._valid_from, services._valid_from) AS _valid_from,
        LEAST(dim._valid_to, services._valid_to) AS _valid_to
    FROM dim
    INNER JOIN services
        ON dim.service_key = services.source_record_id
        AND dim._valid_from < services._valid_to
        AND dim._valid_to > services._valid_from
),

int_transit_database__gtfs_service_data_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['services_join.source_record_id', 'GREATEST(services_join._valid_from, datasets._valid_from)']) }} AS key,
        services_join.name,
        service_key,
        service_name,
        datasets.key AS gtfs_dataset_key,
        datasets.name AS gtfs_dataset_name,
        customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        services_join.fares_v2_status,
        services_join.source_record_id,
        services_join.manual_check__fixed_route_completeness,
        services_join.manual_check__demand_response_completeness,
        services_join.original_record_id,
        (services_join._is_current AND datasets._is_current) AS _is_current,
        GREATEST(services_join._valid_from, datasets._valid_from) AS _valid_from,
        LEAST(services_join._valid_to, datasets._valid_to) AS _valid_to
    FROM services_join
    INNER JOIN datasets
        ON services_join.gtfs_dataset_key = datasets.source_record_id
        AND services_join._valid_from < datasets._valid_to
        AND services_join._valid_to > datasets._valid_from
)

SELECT * FROM int_transit_database__gtfs_service_data_dim
