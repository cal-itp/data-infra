{{ config(materialized='table') }}

WITH int_transit_database__gtfs_datasets_dim AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__download_configs') }}
)

SELECT * FROM int_transit_database__gtfs_datasets_dim
