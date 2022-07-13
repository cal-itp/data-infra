{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__gtfs_datasets'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__gtfs_datasets AS (
    SELECT
        gtfs_dataset_id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        data,
        fares_v2_status,
        fares_notes,
        pathways_status,
        schedule_comments,
        uri,
        future_uri,
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
        dataset_publisher,
        itp_activities,
        itp_schedule_todo,
        deprecated_date,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.aggregated_to) AS unnested_aggregated_to
)

SELECT * FROM stg_transit_database__gtfs_datasets
