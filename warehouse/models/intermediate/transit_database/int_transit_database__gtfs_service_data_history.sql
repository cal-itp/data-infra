{{ config(materialized='table') }}

WITH stg_transit_database__gtfs_service_data AS (
    SELECT *
    FROM {{ ref('stg_transit_database__gtfs_service_data') }}
),

int_gtfs_quality__gtfs_service_data_history AS (
    SELECT
        calitp_extracted_at AS date,
        -- we used to have some records where one single gtfs_service_data record
        -- had one service but multiple datasets, which unnest to non-unique
        -- gtfs_service_data at the day level
        -- we also have some duplicates -- same service/dataset but different gtfs_service_data record
        -- decision was to just use historical data as-is, so we are handling rather than dropping
        {{ dbt_utils.surrogate_key(['key', 'service_key', 'gtfs_dataset_key']) }} AS key,
        key AS gtfs_service_data_key,
        name,
        service_key,
        gtfs_dataset_key,
        customer_facing,
        category
    FROM stg_transit_database__gtfs_service_data
)

SELECT * FROM int_gtfs_quality__gtfs_service_data_history
