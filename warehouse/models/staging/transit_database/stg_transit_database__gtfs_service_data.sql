{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__gtfs_service_data'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__gtfs_service_data AS (
    SELECT
        gtfs_service_data_id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        -- service and gtfs_dataset are 1:1 foreign key fields
        -- but they export as an array from airtable
        -- turn them into a string for joining
        -- JSON_VALUE_ARRAY(services) services,
        -- JSON_VALUE_ARRAY(gtfs_dataset) gtfs_dataset,
        services,
        gtfs_dataset,
        category,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__gtfs_service_data
