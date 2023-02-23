WITH stg_gtfs_rt__trip_updates_validation_outcomes AS (
    {{ gtfs_rt_stg_outcomes('validation', source('external_gtfs_rt', 'trip_updates_validation_outcomes')) }}
)

SELECT * FROM stg_gtfs_rt__trip_updates_validation_outcomes
