{{ config(materialized='table') }}

WITH trips AS (
    SELECT
        feed_key,
        gtfs_dataset_key,
        service_date,
        trip_id,
        trip_instance_key,
    FROM {{ ref('fct_scheduled_trips') }}
),

vp_path AS (
    SELECT
        trip_instance_key,
        pt_array
        FROM {{ ref('fct_vehicle_locations_path') }}
),

stop_times_grouped AS (
    SELECT *
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
        trips.*,
        stop_times_grouped.stop_pt_array,
        stop_times_grouped.stop_id_array,

        vp_path.pt_array,

    FROM trips
    LEFT JOIN stop_times_grouped USING (feed_key, trip_id, iteration_num)
    LEFT JOIN vp_path USING (trip_instance_key)
),

-- unnest the arrays so that every stop_id, stop point geom is a row
unnested_stops AS (
  SELECT
      vp_with_stops.* EXCEPT(stop_pt_array, stop_id_array),
      stop_id,
      pt_geom,
  FROM vp_with_stops
  LEFT JOIN UNNEST(stop_pt_array) AS pt_geom
  LEFT JOIN UNNEST(stop_id_array) AS stop_id
),

-- if vp path gets within 100 meters of stop, it services the stop.
stops_intersecting_vp AS (
    SELECT
        unnested_stops.* EXCEPT(pt_geom, pt_array),

        -- this is a boolean column, use this to aggregate to trip or stop grain
        ST_INTERSECTS(ST_BUFFER(pt_geom, 100), ST_MAKELINE(pt_array)) AS vp_near_stop,
    FROM unnested_stops
)

SELECT * FROM stops_intersecting_vp
