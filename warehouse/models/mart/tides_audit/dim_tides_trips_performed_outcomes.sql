{{ config(materialized='table') }}

WITH dim_tides_trips_performed_outcomes AS (
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
      FROM {{ source('external_tides', 'trips_performed_outcomes') }}
)

SELECT * FROM dim_tides_trips_performed_outcomes
