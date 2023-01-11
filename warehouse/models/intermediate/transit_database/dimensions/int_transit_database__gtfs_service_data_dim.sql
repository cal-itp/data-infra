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
    FROM int_transit_database__gtfs_datasets_dim
),

services AS (
    SELECT *
    FROM int_transit_database__gtfs_services_dim
),


int_transit_database__gtfs_service_data_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', 'GREATEST(dim._valid_from, datasets._valid_from, services._valid_from)']) }} AS key,
        id AS original_record_id,
        name,
        services.key AS service_key,
        datasets.key AS gtfs_dataset_key,
        customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        fares_v2_status,
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

SELECT * FROM int_transit_database__gtfs_service_data_dim
