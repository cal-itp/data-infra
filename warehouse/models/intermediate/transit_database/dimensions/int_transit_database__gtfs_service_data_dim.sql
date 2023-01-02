{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__gtfs_service_data',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['fares_v2_status']
        ) }}
),

int_transit_database__gtfs_service_data_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        name,
        service_key,
        gtfs_dataset_key,
        customer_facing,
        category,
        agency_id,
        network_id,
        route_id,
        fares_v2_status,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__gtfs_service_data_dim
