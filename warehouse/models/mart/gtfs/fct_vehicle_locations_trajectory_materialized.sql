{{
    config(
        materialized='table',
    )
}}

SELECT * FROM {{ ref('fct_vehicle_locations_trajectory') }}
