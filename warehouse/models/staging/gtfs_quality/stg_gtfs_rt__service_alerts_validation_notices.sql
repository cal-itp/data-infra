{{ config(materialized='table') }}

WITH stg_gtfs_rt__service_alerts_validation_notices AS (
    {{ gtfs_rt_stg_validation_notices(source('external_gtfs_rt', 'service_alerts_validation_notices')) }}
)

SELECT * FROM stg_gtfs_rt__service_alerts_validation_notices
