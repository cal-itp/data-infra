{{ config(materialized='table') }}

WITH int_gtfs_rt__distinct_download_configs AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt__distinct_download_configs') }}
),

gtfs_download_configs AS (
    SELECT *
    FROM {{ ref('dim_gtfs_download_configs') }}
),

int_gtfs_rt__daily_url_index AS (
    SELECT

        configs.dt,
        gtfs_download_configs.url AS string_url,
        {{ to_url_safe_base64('gtfs_download_configs.url') }} AS base64_url,
        gtfs_download_configs.feed_type AS type

    FROM int_gtfs_rt__distinct_download_configs AS configs
    LEFT JOIN gtfs_download_configs
        ON configs._config_extract_ts = gtfs_download_configs.ts
    WHERE gtfs_download_configs.feed_type IN ("service_alerts", "vehicle_positions", "trip_updates")
)

SELECT * FROM int_gtfs_rt__daily_url_index
