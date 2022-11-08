WITH stg_gtfs_rt__trip_updates_validation_notices AS (
    {{ gtfs_rt_stg_validation_notices(source('external_gtfs_rt', 'trip_updates_validation_notices')) }}
)

SELECT * FROM stg_gtfs_rt__trip_updates_validation_notices
