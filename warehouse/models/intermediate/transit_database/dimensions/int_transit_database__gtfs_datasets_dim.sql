{{ config(materialized='table') }}

WITH dim AS (
    {{ transit_database_make_historical_dimension(
        once_daily_staging_table = 'stg_transit_database__gtfs_datasets',
        date_col = 'dt',
        record_id_col = 'id',
        array_cols = ['fares_v2_status', 'provider', 'operator',
        'gtfs_service_mapping', 'dataset_producers', 'dataset_publisher']
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
        aggregated_to_gtfs_dataset_key,
        provider_gtfs_capacity,
        notes,
        provider,
        operator,
        gtfs_service_mapping,
        dataset_producers,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,
        dataset_publisher,
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
