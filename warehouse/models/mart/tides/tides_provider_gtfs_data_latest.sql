{{
    config(
        materialized='view',
        tags=['tides_reference'],
    )
}}

WITH tides_provider_gtfs_data_latest AS (
    SELECT * FROM {{ ref('tides_provider_gtfs_data') }}
    WHERE _is_current
)

SELECT * FROM tides_provider_gtfs_data_latest
