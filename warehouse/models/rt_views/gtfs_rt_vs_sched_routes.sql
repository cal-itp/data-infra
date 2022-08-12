WITH 
gtfs_rt_vp_distinct_trips AS (
    SELECT DISTINCT
     calitp_itp_id,
     calitp_url_number,
     date,
     trip_id,
     trip_route_id,
     vehicle_id
    FROM {{ ref('stg_rt__vehicle_positions') }}
    WHERE calitp_itp_id = 300
        AND date between '2022-04-01' AND '2022-06-30'
),

vp_trips AS(
SELECT 
  date AS service_date, 
  trip_id AS vp_trip_id, 
  calitp_itp_id, 
  calitp_url_number
FROM gtfs_rt_vp_distinct_trips
WHERE date BETWEEN '2022-04-01' AND '2022-06-30'
),

sched_trips AS(
SELECT 
  trip_id, 
  route_id,
  service_date, 
  calitp_itp_id, 
  calitp_url_number
FROM {{ref('gtfs_schedule_fact_daily_trips')}}
WHERE (calitp_itp_id=300
    AND service_date BETWEEN '2022-04-01' AND '2022-06-30'
    AND is_in_service = True)
),
rt_sched_joined AS(
  SELECT
  T1.calitp_itp_id,
  T1.calitp_url_number,
  T1.route_id,
  T1.service_date,
    COUNT(T1.trip_id) AS num_sched,
    COUNT(T2.vp_trip_id) AS num_vp,
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
with_percent AS(
  SELECT
  T1.calitp_itp_id,
  T2.agency_name,
  T1.calitp_url_number,
  T1.route_id,
  T2.route_short_name,
  T1.service_date,
  T1.num_sched,
  T1.num_vp,
  num_vp/num_sched AS pct_w_vp
  FROM rt_sched_joined AS T1
  LEFT JOIN {{ref('gtfs_schedule_dim_routes')}} AS T2
    ON
      T1.route_id = T2.route_id
      AND T1.calitp_itp_id = T2.calitp_itp_id
      AND T1.calitp_url_number = T2.calitp_url_number
)
SELECT * 
FROM with_percent