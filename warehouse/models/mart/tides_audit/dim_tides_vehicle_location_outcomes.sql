{{ config(materialized='table') }}

WITH dim_tides_vehicle_location_outcomes AS (
    SELECT DISTINCT
           display_name,
           organization_source_record_id,
           base64_url,
           dataset_name,
           table_name,
           destination_path,
           dt,
           ts
      FROM {{ source('external_tides', 'vehicle_location_outcomes') }}
)

SELECT * FROM dim_tides_vehicle_location_outcomes
