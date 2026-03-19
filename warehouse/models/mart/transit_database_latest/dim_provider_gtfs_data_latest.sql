WITH
dim_provider_gtfs_data_latest AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
    WHERE _is_current
)

SELECT * FROM dim_provider_gtfs_data_latest
