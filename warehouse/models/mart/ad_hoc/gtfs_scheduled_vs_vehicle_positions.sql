WITH
vp_trips AS (
  SELECT
      gtfs_dataset_key AS vp_gtfs_dataset_key,
      base64_url,
      dt AS service_date,
      _gtfs_dataset_name AS vp_gtfs_dataset_name,
      trip_route_id,
      count(distinct trip_id) AS num_vp_trips
  FROM {{ ref('fct_vehicle_locations') }}
  WHERE ((dt = '2023-02-08'))
  GROUP BY 1, 2, 3, 4, 5),

sched_trips AS(
  SELECT 
    gtfs_dataset_key AS sched_gtfs_dataset_key,
    agency_id,
    name AS sched_gtfs_dataset_name,
    service_date,
    route_id,
    route_short_name,
    count(distinct trip_id) AS num_sched_trips
FROM {{ref('fct_daily_scheduled_trips')}}
WHERE ((service_date = '2023-02-08'))
GROUP BY 1, 2, 3, 4, 5, 6),

rt_sched_joined AS (
  SELECT
    T1.sched_gtfs_dataset_key,
    T2.vp_gtfs_dataset_key,
    T1.service_date,
    T1.agency_id,
    T1.route_id,
    T2.trip_route_id,
    T1.route_short_name,
    T1.sched_gtfs_dataset_name,
    T2.vp_gtfs_dataset_name,
    T1.num_sched_trips,
    T2.num_vp_trips
  FROM sched_trips as T1
  LEFT JOIN vp_trips as T2
    ON
      T1.route_id = T2.trip_route_id
      AND T1.service_date = T2.service_date
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
)
,

gtfs_scheduled_vs_vehicle_positions AS (
  SELECT
    T1.sched_gtfs_dataset_key,
    T1.vp_gtfs_dataset_key,
    T1.service_date,
    T2.organization_name,
    T1.route_id,
    T1.route_short_name,
    T1.sched_gtfs_dataset_name,
    T1.vp_gtfs_dataset_name,
    T1.num_sched_trips,
    T1.num_vp_trips,
    num_vp_trips/num_sched_trips AS pct_trips_w_vp
  FROM rt_sched_joined as T1
    LEFT JOIN {{ref('dim_provider_gtfs_data')}} as T2
      ON T1.sched_gtfs_dataset_key = T2.schedule_gtfs_dataset_key
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
)

SELECT *
FROM gtfs_scheduled_vs_vehicle_positions