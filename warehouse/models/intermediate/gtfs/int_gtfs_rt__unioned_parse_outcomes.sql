WITH service_alerts AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__service_alerts_outcomes') }}
),

vehicle_positions AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__vehicle_positions_outcomes') }}
),

trip_updates AS (
    SELECT *
    FROM {{ ref('stg_gtfs_rt__trip_updates_outcomes') }}
),

int_gtfs_rt__unioned_parse_outcomes AS (
    SELECT *
    FROM service_alerts
    UNION ALL
    SELECT * FROM vehicle_positions
    UNION ALL
    SELECT * FROM trip_updates
)

SELECT * FROM int_gtfs_rt__unioned_parse_outcomes
