

WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__gtfs_service_data'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__gtfs_service_data AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        unnested_services AS service_key,
        unnested_gtfs_dataset AS gtfs_dataset_key,
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
        unnested_reference_static_gtfs_service AS reference_static_gtfs_service_data_key,
        uri,
        currently_operating__from_services_,
        provider_reporting_category,
        itp_schedule_todo__from_gtfs_dataset_,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.services) as unnested_services
    LEFT JOIN UNNEST(latest.gtfs_dataset) as unnested_gtfs_dataset
    LEFT JOIN UNNEST(latest.reference_static_gtfs_service) as unnested_reference_static_gtfs_service
)

SELECT * FROM stg_transit_database__gtfs_service_data
