{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__gtfs_datasets',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['fares_v2_status', 'service_type', 'category',
        'referenced_gtfs__from_gtfs_service_mapping_', 'provider', 'operator',
        'provider_reporting_category__from_gtfs_service_mapping_', 'feed_metrics',
        'gtfs_service_mapping', 'services', 'dataset_producers', 'dataset_publisher',
        'itp_activities', 'itp_schedule_todo']
        ) }}
),

int_transit_database__gtfs_datasets_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        name,
        data,
        data_quality_pipeline,
        regional_feed_type,
        fares_v2_status,
        fares_notes,
        pathways_status,
        schedule_comments,
        uri,
        future_uri,
        pipeline_url,
        api_key,
        aggregated_to_gtfs_dataset_key,
        provider_gtfs_capacity,
        service_type,
        category,
        notes,
        referenced_gtfs__from_gtfs_service_mapping_,
        provider,
        operator,
        provider_reporting_category__from_gtfs_service_mapping_,
        feed_metrics,
        gtfs_service_mapping,
        services,
        dataset_producers,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        dataset_publisher,
        itp_activities,
        itp_schedule_todo,
        deprecated_date,
        authorization_url_parameter_name,
        url_secret_key_name,
        authorization_header_parameter_name,
        header_secret_key_name,
        url_to_encode,
        base64_url,
        type,
        _is_current,
        _valid_from,
        _valid_to
    FROM dim
)

SELECT * FROM int_transit_database__gtfs_datasets_dim
