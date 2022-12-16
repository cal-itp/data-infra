{{ config(materialized='table') }}

WITH stg_transit_database__gtfs_datasets AS (
    SELECT *
    FROM {{ ref('stg_transit_database__gtfs_datasets') }}
),

int_gtfs_quality__gtfs_datasets_history AS (
    SELECT
        calitp_extracted_at AS date,
        key,
        name,
        data,
        regional_feed_type,
        base64_url
    FROM stg_transit_database__gtfs_datasets
)

SELECT * FROM int_gtfs_quality__gtfs_datasets_history
