{{ config(materialized='table') }}

WITH dim_tides_vehicle_locations_outcomes AS (
    SELECT DISTINCT
           display_name,
           organization_source_record_id,
           base64_url,
           dataset_name,
           table_name,
           destination_path,
           service_date,
           dt,
           ts
      FROM {{ source('external_tides', 'vehicle_locations_outcomes') }}
)

SELECT * FROM dim_tides_vehicle_locations_outcomes
