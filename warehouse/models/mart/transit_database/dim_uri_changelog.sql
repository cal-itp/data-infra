{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__uri_changelog') }}
),
dim_uri_changelog AS (
    SELECT 
        source_record_id,
        name,
        uri,
        first_downloaded_dt,
        last_downloaded_dt,
    FROM dim 
    ORDER BY first_downloaded_dt DESC
)
SELECT * from dim_uri_changelog