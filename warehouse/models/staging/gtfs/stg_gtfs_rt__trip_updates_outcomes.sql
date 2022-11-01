WITH stg_gtfs_rt__service_alerts_outcomes AS
    (
        {{ gtfs_rt_stg_parse_outcomes(source('external_gtfs_rt', 'trip_updates_outcomes')) }}
    )

SELECT * FROM stg_gtfs_rt__service_alerts_outcomes
