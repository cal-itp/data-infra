{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        *
    FROM cal-itp-data-infra.mart_gtfs.fct_vehicle_locations
    WHERE trip_instance_key = '32034bff4a0692bab4e31d303bd5276d' AND service_date = DATE('2025-02-12')
    ORDER by service_date, trip_instance_key, location_timestamp
)

SELECT * FROM fct_vehicle_locations
