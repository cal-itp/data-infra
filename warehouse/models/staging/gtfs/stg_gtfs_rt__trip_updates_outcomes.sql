{{ config(materialized='table') }}

WITH stg_gtfs_rt__trip_updates_outcomes AS (
    {{ gtfs_rt_stg_outcomes('parse', source('external_gtfs_rt', 'trip_updates_outcomes')) }}
)

SELECT * FROM stg_gtfs_rt__trip_updates_outcomes
