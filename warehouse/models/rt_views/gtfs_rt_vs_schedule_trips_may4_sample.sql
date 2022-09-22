WITH
-- selecting the distinct trips from GTFS Vehicle Postions for all operators
vp_trips AS (
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        date AS service_date,
        trip_id AS vp_trip_id
    -- trip_route_id
    -- note: to change when we want to include more operators. trip_route_id and trip_id aare optional
    -- https://gtfs.org/realtime/reference/#message-vehicleposition
    FROM {{ ref('stg_rt__vehicle_positions') }}
    WHERE date = '2022-05-04'
),

--- selecting GTFS schedule data for all operators
sched_trips AS (
    SELECT
        trip_id,
        route_id,
        service_date,
        calitp_itp_id,
        calitp_url_number
    FROM {{ ref('gtfs_schedule_fact_daily_trips') }}
    WHERE service_date = '2022-05-04'
        AND (is_in_service = True)
),

-- joining Vehicle Position data and Scheduled data on service date, trip id and itp id and url number
rt_sched_joined AS (
    SELECT
        T1.calitp_itp_id,
        T1.calitp_url_number,
        T1.route_id,
        T1.service_date,
        COUNT(T1.trip_id) AS num_sched,
        COUNT(T2.vp_trip_id) AS num_vp
    -- num_vp/num_sched AS pct_w_vp
    FROM sched_trips AS T1
    LEFT JOIN vp_trips AS T2
        ON
            T1.trip_id = T2.vp_trip_id
            AND T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.service_date = T2.service_date
    GROUP BY 1, 2, 3, 4
),

-- getting the percent of scheduled trips with vehicle position data and adding the common route name
gtfs_rt_vs_schedule_trips_may4_sample AS (
    SELECT
        T1.calitp_itp_id,
        T2.agency_name,
        T1.calitp_url_number,
        T1.route_id,
        T2.route_short_name,
        T1.service_date,
        T2.calitp_extracted_at,
        T2.calitp_deleted_at,
        T1.num_sched,
        T1.num_vp,
        num_vp / num_sched AS pct_w_vp
    FROM rt_sched_joined AS T1
    LEFT JOIN {{ ref('gtfs_schedule_dim_routes') }} AS T2
        ON
            T1.route_id = T2.route_id
            AND T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.service_date BETWEEN T2.calitp_extracted_at AND T2.calitp_deleted_at
)

SELECT *
FROM gtfs_rt_vs_schedule_trips_may4_sample
