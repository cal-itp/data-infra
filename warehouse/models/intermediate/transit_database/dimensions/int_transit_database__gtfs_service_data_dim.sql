{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__gtfs_service_data',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['dataset_type', 'provider', 'operator',
            'dataset_producers__from_gtfs_dataset_',
            'dataset_publisher__from_gtfs_dataset_',
            'gtfs_dataset_type',
            'pathways_status',
            'fares_v2_status',
            'service_type__from_services_',
            'flex_status',
            'schedule_comments__from_gtfs_dataset_',
            'itp_activities__from_gtfs_dataset_',
            'fares_notes__from_gtfs_dataset_',
            'uri',
            'provider_reporting_category',
            'itp_schedule_todo__from_gtfs_dataset_'
            ]
        ) }}
),

int_transit_database__gtfs_service_data_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        name,
        service_key,
        gtfs_dataset_key,
        dataset_type,
        customer_facing,
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
        uri,
        provider_reporting_category,
        itp_schedule_todo__from_gtfs_dataset_,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__gtfs_service_data_dim
