{{ config(materialized='table') }}

WITH dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__uri_changelog') }}
),
dim_uri_changelog AS (
    SELECT 
        id,
        name,
        uri,
        first_downloaded_dt,
        last_downloaded_dt,
    FROM lagged_uri_table 
    ORDER BY dt DESC
)
SELECT * from dim_uri_changelog