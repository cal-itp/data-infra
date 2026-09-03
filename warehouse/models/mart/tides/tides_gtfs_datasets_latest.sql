{{
    config(
        materialized='view',
        tags=['tides_reference'],
    )
}}

WITH tides_gtfs_datasets_latest AS (
    SELECT * FROM {{ ref('tides_gtfs_datasets') }}
    WHERE _is_current
)

SELECT * FROM tides_gtfs_datasets_latest
