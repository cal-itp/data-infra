{{ config(materialized='table') }}

WITH stg_gtfs_rt__service_alerts_outcomes AS (
    {{ gtfs_rt_stg_outcomes('parse', source('external_gtfs_rt', 'service_alerts_outcomes')) }}
)

SELECT * FROM stg_gtfs_rt__service_alerts_outcomes
