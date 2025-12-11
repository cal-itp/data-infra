{{ config(materialized='table') }}

WITH lagged_uri_table AS (
  SELECT 
      id AS source_record_id,
      name,
      uri,
      LAG (uri) OVER (
        PARTITION BY id 
        ORDER BY dt
      ) AS previous_uri,
      dt AS first_downloaded_dt ,

  FROM {{ref('dim_gtfs_datasets')}}
)
int_transit_database__uri_changelog AS (
    SELECT 
        id,
        name,
        uri,
        first_downloaded_dt,
        LEAD (first_downloaded_dt) OVER (
            PARTITION BY id
            ORDER BY dt
        ) - 1 AS last_downloaded_dt,
    FROM lagged_uri_table 
    WHERE previous_uri != uri
)
SELECT * FROM int_transit_database__uri_changelog