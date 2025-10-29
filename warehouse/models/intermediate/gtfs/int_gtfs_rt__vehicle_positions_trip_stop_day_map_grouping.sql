{{
    config(
        materialized='incremental',
        incremental_strategy = 'insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day'
        }, cluster_by=['dt', 'vp_base64_url', 'feed_key']
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
        base64_url AS vp_base64_url,
    FROM {{ ref('fct_daily_rt_feed_files') }} AS t1
    WHERE t1.date >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY) AND feed_type = "vehicle_positions"
    -- write the where filter this way, because the column is called date, not working with incremental_where macro
),

int_vp_trips AS (
    SELECT DISTINCT
        dt,
        service_date,
        base64_url,
        trip_id,
    FROM {{ ref('int_gtfs_rt__vehicle_positions_trip_day_map_grouping') }}
    WHERE {{ incremental_where(
        default_start_var='PROD_GTFS_RT_START',
        this_dt_column='dt',
        filter_dt_column='dt')
    }}
),

vp_trips AS (
    SELECT DISTINCT
        service_date,
        base64_url,
        trip_id,
        trip_instance_key,
    FROM {{ ref('fct_vehicle_positions_trip_summaries') }}
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
        default_start_var='PROD_GTFS_RT_START',
        this_dt_column='dt',
        filter_dt_column='dt')
    }}
),

schedule_joins AS (
    SELECT
        int_vp_trips.dt,
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
    INNER JOIN vp_trips
        ON trips.service_date = vp_trips.service_date
        AND daily_rt_feeds.vp_base64_url = vp_trips.base64_url
        AND trips.trip_id = vp_trips.trip_id
        AND trips.trip_instance_key = vp_trips.trip_instance_key
    INNER JOIN int_vp_trips
        ON trips.service_date = int_vp_trips.service_date
        AND vp_trips.base64_url = int_vp_trips.base64_url
        AND vp_trips.trip_id = int_vp_trips.trip_id
),

vp_near_stops AS (
   SELECT
        schedule_joins.dt,
        schedule_joins.service_date,
        schedule_joins.vp_base64_url,
        vehicle_locations.key AS vp_key,
        --vehicle_locations.location,

        schedule_joins.feed_key,
        schedule_joins.trip_instance_key,
        schedule_joins.stop_id,
        schedule_joins.st_trip_key, -- use to key back into schedule trip info found in stop times (int_gtfs_schedule__stop_times_grouped)
        --schedule_joins.pt_geom,

        MIN(ROUND(ST_DISTANCE(vehicle_locations.location, schedule_joins.pt_geom), 2)) AS distance_meters,
        --ST_CLOSESTPOINT(vehicle_locations.location, schedule_joins.pt_geom) is returning a point useful? It'll be difficult to match against, use vp_keys instead and distances

    FROM schedule_joins
    INNER JOIN vehicle_locations
        ON schedule_joins.vp_base64_url = vehicle_locations.base64_url
        AND schedule_joins.service_date = vehicle_locations.service_date
        AND schedule_joins.trip_instance_key = vehicle_locations.trip_instance_key
        AND ST_DWITHIN(vehicle_locations.location, schedule_joins.pt_geom, 100)
        -- 100 meters ~ 0.1 miles, 328 ft
    GROUP BY dt, service_date, vp_base64_url, feed_key, trip_instance_key, stop_id, st_trip_key, vp_key
),


vp_counts_near_stops AS (
    SELECT
        dt,
        service_date,
        vp_base64_url,
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
    GROUP BY dt, service_date, vp_base64_url, feed_key, trip_instance_key, stop_id, st_trip_key
)

SELECT * FROM vp_counts_near_stops
