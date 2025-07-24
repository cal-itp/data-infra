{{ config(materialized='table') }}

WITH stg_gtfs_rt__vehicle_positions_outcomes AS (
    {{ gtfs_rt_stg_outcomes('parse', source('external_gtfs_rt', 'vehicle_positions_outcomes')) }}
)

SELECT * FROM stg_gtfs_rt__vehicle_positions_outcomes
