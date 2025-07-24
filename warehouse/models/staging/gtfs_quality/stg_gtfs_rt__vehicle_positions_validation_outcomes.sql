{{ config(materialized='table') }}

WITH stg_gtfs_rt__vehicle_positions_validation_outcomes AS (
    {{ gtfs_rt_stg_outcomes('validation', source('external_gtfs_rt', 'vehicle_positions_validation_outcomes')) }}
)

SELECT * FROM stg_gtfs_rt__vehicle_positions_validation_outcomes
