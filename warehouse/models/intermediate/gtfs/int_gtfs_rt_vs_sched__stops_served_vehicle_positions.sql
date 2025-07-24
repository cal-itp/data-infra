{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['vp_base64_url', 'schedule_feed_key'],
    )
}}

WITH trips AS (
    SELECT
        feed_key,
        gtfs_dataset_key,
        service_date,
        trip_id,
        iteration_num,
        trip_instance_key,
    FROM {{ ref('fct_scheduled_trips') }}
    --FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`
    -- clustered by service_date
),

vp_path AS (
    SELECT
        service_date,
        base64_url,
        schedule_feed_key,
        trip_instance_key,
        ST_SIMPLIFY(ST_MAKELINE(pt_array), 5) AS pt_array
    --FROM {{ ref('fct_vehicle_locations_path') }}
    FROM `cal-itp-data-infra-staging.tiffany_mart_gtfs.test_vp_path`
    -- clustered by base64_url, schedule_feed_key, partitioned by service_date
),

stop_times_grouped AS (
    SELECT
        feed_key,
        trip_id,
        iteration_num,
        stop_pt_array,
        stop_id_array,
    FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
    -- clustered by feed_key
),

-- trip_grain: join trips to vp_path and attach an array of stop positions
-- start with inner join otherwise query takes quite awhile
vp_with_stops AS (
  SELECT
        trips.feed_key AS schedule_feed_key,
        trips.gtfs_dataset_key AS schedule_gtfs_dataset_key,
        trips.service_date,
        trips.trip_id,
        trips.iteration_num,
        trips.trip_instance_key,

        stop_times_grouped.stop_pt_array,
        stop_times_grouped.stop_id_array,

        vp_path.base64_url AS vp_base64_url,
        vp_path.pt_array,

    FROM trips
    INNER JOIN stop_times_grouped
        ON stop_times_grouped.feed_key = trips.feed_key
        AND stop_times_grouped.trip_id = trips.trip_id
        AND stop_times_grouped.iteration_num = trips.iteration_num
    INNER JOIN vp_path
        ON trips.service_date = vp_path.service_date
        AND trips.feed_key = vp_path.schedule_feed_key
        AND trips.trip_instance_key = vp_path.trip_instance_key
),

-- unnest the arrays so that every stop_id, stop point geom is a row
unnested_stops AS (
    SELECT
        vp_with_stops.* EXCEPT(stop_pt_array, stop_id_array),
        stop_id,
        ST_BUFFER(pt_geom, 50) AS stop_buff50,
        ST_BUFFER(pt_geom, 25) AS stop_buff25,
        ST_BUFFER(pt_geom, 10) AS stop_buff10,

    FROM vp_with_stops
    LEFT JOIN UNNEST(stop_pt_array) AS pt_geom
    LEFT JOIN UNNEST(stop_id_array) AS stop_id
),

stops_intersecting_vp AS (
    SELECT
        unnested_stops.* EXCEPT(stop_buff50, stop_buff25, stop_buff10, pt_array),

        -- this is a boolean column, use this to aggregate to trip or stop grain
        -- probably want to be around 25m? 10m might be too aggressively close,
        -- but 50m or 100m might be rather generous
        ST_INTERSECTS(stop_buff50, pt_array) AS near_stop_50m,
        ST_INTERSECTS(stop_buff25, pt_array) AS near_stop_25m,
        ST_INTERSECTS(stop_buff10, pt_array) AS near_stop_10m,

    FROM unnested_stops
)

SELECT * FROM stops_intersecting_vp
