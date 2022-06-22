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
        uri,
        future_uri,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__gtfs_datasets
