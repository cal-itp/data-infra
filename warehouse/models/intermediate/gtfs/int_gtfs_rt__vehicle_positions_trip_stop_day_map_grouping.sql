{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['service_date', 'base64_url']
    )
}}


WITH trips AS (
    SELECT
        feed_key,
        service_date,
        trip_id,
        trip_instance_key,
        trip_first_departure_sec,
    FROM {{ ref('fct_scheduled_trips') }}
),

stop_times_grouped AS (
    SELECT
        key, -- from feed_key, trip_id, trip_first_departure_sec
        feed_key,
        trip_id,
        trip_first_departure_sec,
        stop_id_array,

    FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
),

stops AS (
    SELECT
        feed_key,
        service_date,
        stop_id,
        pt_geom,

    FROM {{ ref('fct_daily_scheduled_stops') }}
    WHERE {{ incremental_where(
        default_start_var='GTFS_SCHEDULE_START',
        this_dt_column='service_date',
        filter_dt_column='service_date')
    }}
),

daily_rt_feeds AS (
    SELECT DISTINCT
        schedule_feed_key,
        base64_url AS vp_base64_url
    FROM `cal-itp-data-infra.mart_gtfs.fct_daily_rt_feed_files` AS t1--{{ ref('fct_daily_rt_feed_files') }} AS t1
    WHERE t1.date > "2025-09-30" AND feed_type = "vehicle_positions"
),

vehicle_locations AS (
    SELECT
        key,
        dt,
        service_date,
        base64_url,
        trip_instance_key,
        location

    FROM {{ ref('fct_vehicle_locations') }}
    WHERE {{ incremental_where(
        default_start_var='PROD_GTFS_RT_START')
    }}
),

schedule_joins AS (
    SELECT
        trips.feed_key,
        trips.service_date,
        trips.trip_instance_key,
        stop_times_grouped.key AS st_trip_key,
        stop_id,
        stops.pt_geom,
        daily_rt_feeds.vp_base64_url,

    FROM trips
    INNER JOIN stop_times_grouped
        ON trips.feed_key = stop_times_grouped.feed_key
        AND trips.trip_id = stop_times_grouped.trip_id
        AND trips.trip_first_departure_sec = stop_times_grouped.trip_first_departure_sec
    -- use trip_first_departure_sec instead of iteration_num because scheduled_trips does more coalescing on iteration_num, so we might not match it
    LEFT JOIN UNNEST(stop_times_grouped.stop_id_array) AS stop_id
    INNER JOIN stops
        ON trips.feed_key = stops.feed_key
        AND trips.service_date = stops.service_date
        AND stop_id = stops.stop_id
    INNER JOIN daily_rt_feeds
        ON trips.feed_key = daily_rt_feeds.schedule_feed_key
),

vp_near_stops AS (
    SELECT
        vehicle_locations.service_date,
        vehicle_locations.base64_url,
        vehicle_locations.key AS vp_key,
        --vehicle_locations.location,

        schedule_joins.feed_key,
        schedule_joins.trip_instance_key,
        schedule_joins.stop_id,
        schedule_joins.st_trip_key, -- use to key back into schedule trip info found in stop times (int_gtfs_schedule__stop_times_grouped)
        --schedule_joins.pt_geom,

        ROUND(ST_DISTANCE(vehicle_locations.location, schedule_joins.pt_geom), 2) AS distance_meters,
        --ST_CLOSESTPOINT(vehicle_locations.location, schedule_joins.pt_geom) is returning a point useful? It'll be difficult to match against, use vp_keys instead and distances

    FROM vehicle_locations
    INNER JOIN daily_rt_feeds
        ON daily_rt_feeds.vp_base64_url = vehicle_locations.base64_url
    INNER JOIN schedule_joins
        ON schedule_joins.vp_base64_url = vehicle_locations.base64_url
        AND schedule_joins.service_date = vehicle_locations.service_date
        AND schedule_joins.trip_instance_key = vehicle_locations.trip_instance_key
        AND ST_DWITHIN(vehicle_locations.location, schedule_joins.pt_geom, 100)
        -- 100 meters ~ 0.1 miles, 328 ft
),

vp_counts_near_stops AS (
    SELECT
        service_date,
        base64_url,
        feed_key,
        trip_instance_key,
        stop_id,
        st_trip_key,

        COUNTIF(distance_meters <= 100) AS near_100m,
        COUNTIF(distance_meters <= 50) AS near_50m,
        COUNTIF(distance_meters <= 25) AS near_25m,
        COUNTIF(distance_meters <= 10) AS near_10m,
        ARRAY_AGG(distance_meters ORDER BY distance_meters, vp_key) AS distance_meters_array,
        ARRAY_AGG(vp_key ORDER BY distance_meters, vp_key) AS vp_key_array,

    FROM vp_near_stops
    GROUP BY service_date, base64_url, feed_key, trip_instance_key, stop_id, st_trip_key
)

SELECT * FROM vp_counts_near_stops
