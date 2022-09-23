

WITH
once_daily_gtfs_datasets AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__gtfs_datasets'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__gtfs_datasets AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        data,
        data_quality_pipeline,
        fares_v2_status,
        fares_notes,
        pathways_status,
        schedule_comments,
        uri,
        future_uri,
        pipeline_url,
        api_key,
        unnested_aggregated_to AS aggregated_to_gtfs_dataset_key,
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
        unnested_schedule_to_use_for_rt_validation AS schedule_to_use_for_rt_validation_gtfs_dataset_key,
        dataset_publisher,
        itp_activities,
        itp_schedule_todo,
        deprecated_date,
        authorization_url_parameter_name,
        url_secret_key_name,
        authorization_header_parameter_name,
        header_secret_key_name,
        CASE
            WHEN ts < CAST("2022-09-15" AS TIMESTAMP) THEN {{ to_url_safe_base64('REGEXP_REPLACE(uri, r"\?([a-zA-Z]+={{[a-zA-Z\s]}})", "")') }}
            ELSE {{ to_url_safe_base64('pipeline_url') }}
        END AS base64_url,
        ts,
        dt AS calitp_extracted_at
    FROM once_daily_gtfs_datasets
    LEFT JOIN UNNEST(once_daily_gtfs_datasets.aggregated_to) AS unnested_aggregated_to
    LEFT JOIN UNNEST(once_daily_gtfs_datasets.schedule_to_use_for_rt_validation) AS unnested_schedule_to_use_for_rt_validation
)

SELECT * FROM stg_transit_database__gtfs_datasets
