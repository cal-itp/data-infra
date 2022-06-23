{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__gtfs_service_data'),
        order_by = 'dt DESC, time DESC'
        ) }}
),
-- holdover from old sql, replace the below with the unnesting from laurie
        -- service and gtfs_dataset are 1:1 foreign key fields
        -- but they export as an array from airtable
        -- turn them into a string for joining
        -- JSON_VALUE_ARRAY(services) services,
        -- JSON_VALUE_ARRAY(gtfs_dataset) gtfs_dataset,

stg_transit_database__gtfs_service_data AS (
    SELECT
        gtfs_service_data_id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        services,
        gtfs_dataset,
        dataset_type,
        category,
        agency_id,
        network_id,
        route_id,
        provider,
        operator,
        dataset_producers__from_gtfs_dataset_,
        dataset_publisher__from_gtfs_dataset_,
        gtfs_dataset_type,
        pathways_status,
        fares_v2_status,
        service_type__from_services_,
        flex_status,
        schedule_comments__from_gtfs_dataset_,
        itp_activities__from_gtfs_dataset_,
        fares_notes__from_gtfs_dataset_,
        reference_static_gtfs_service,
        uri,
        currently_operating__from_services_,
        provider_reporting_category,
        itp_schedule_todo__from_gtfs_dataset_,
        time,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__gtfs_service_data
