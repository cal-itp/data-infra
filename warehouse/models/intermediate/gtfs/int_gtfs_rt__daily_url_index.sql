{{ config(materialized='table') }}

WITH int_gtfs_rt__distinct_download_configs AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__distinct_download_configs') }}
),

stg_transit_database__gtfs_datasets AS (
    SELECT *
    FROM {{ ref('stg_transit_database__gtfs_datasets') }}
),

int_gtfs_rt__daily_url_index AS (
    SELECT
        configs.dt,
        url_to_encode AS string_url,
        base64_url,
        data AS type
    FROM int_gtfs_rt__distinct_download_configs AS configs
    LEFT JOIN stg_transit_database__gtfs_datasets AS datasets
        ON configs._config_extract_ts = datasets.ts
    WHERE data IN ("GTFS Alerts", "GTFS VehiclePositions", "GTFS TripUpdates")
    QUALIFY RANK() OVER (PARTITION BY configs.dt, url_to_encode, base64_url ORDER BY _config_extract_ts DESC) = 1
)

SELECT * FROM int_gtfs_rt__daily_url_index
