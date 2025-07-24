{{
    config(
        materialized='incremental',
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
),

vp_path AS (
    SELECT
        service_date,
        base64_url,
        schedule_feed_key,
        trip_instance_key,
        ST_SIMPLIFY(ST_MAKELINE(pt_array), 5) AS pt_array

    FROM {{ ref('fct_vehicle_locations_path') }}
),

stop_times_grouped AS (
    SELECT
        feed_key,
        trip_id,
        iteration_num,
        stop_pt_array,
        stop_id_array,
    FROM {{ ref('int_gtfs_schedule__stop_times_grouped') }}
),

-- trip_grain: join trips to vp_path and attach an array of stop positions
vp_with_stops AS (
  SELECT
        trips.feed_key AS schedule_feed_key,
        trips.gtfs_dataset_key AS schedule_gtfs_dataset_key,
        trips.service_date,
        trips.trip_id,
        trips.iteration_num,
        trips.trip_instance_key,

        --stop_times_grouped.stop_pt_array,
        --stop_times_grouped.stop_id_array,

        vp_path.base64_url AS vp_base64_url,
        --vp_path.pt_array,

        pt_geom,
        stop_id,
        ST_HAUSDORFFDWITHIN(
            pt_geom, vp_path.pt_array, 25
        ) AS is_within_25m,

    FROM trips
    INNER JOIN stop_times_grouped
        ON stop_times_grouped.feed_key = trips.feed_key
        AND stop_times_grouped.trip_id = trips.trip_id
        AND stop_times_grouped.iteration_num = trips.iteration_num
    INNER JOIN vp_path
        ON trips.service_date = vp_path.service_date
        AND trips.feed_key = vp_path.schedule_feed_key
        AND trips.trip_instance_key = vp_path.trip_instance_key
    LEFT JOIN UNNEST(stop_times_grouped.stop_pt_array) AS pt_geom
    LEFT JOIN UNNEST(stop_times_grouped.stop_id_array) AS stop_id
)

-- unnest the arrays so that every stop_id/stop pt_geom is a row
-- becomes trip-stop grain
--unnested_stops AS (
--    SELECT
--        vp_with_stops.* EXCEPT(stop_pt_array, stop_id_array),
--        stop_id,

        -- tried buffering stop pt geom to various distances,
        -- but BQ resources were exhausted working with ST_SIMPLIFY(pt_array, 5)
        -- so let's use distance to get at a similar metric
        --ROUND(ST_DISTANCE(pt_geom, pt_array), 2) AS meters_to_vp

--    FROM vp_with_stops
--    LEFT JOIN UNNEST(stop_pt_array) AS pt_geom
--    LEFT JOIN UNNEST(stop_id_array) AS stop_id
--)

SELECT * FROM vp_with_stops
