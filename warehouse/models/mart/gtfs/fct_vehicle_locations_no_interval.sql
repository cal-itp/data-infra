{{ config(materialized='view') }}

SELECT * EXCEPT (trip_start_time_interval)
FROM {{ ref('fct_vehicle_locations') }}
