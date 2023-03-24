-- {{ config(
--     materialized='incremental',
--     incremental_strategy='insert_overwrite',
--     partition_by = {
--         'field': 'dt',
--         'data_type': 'date',
--         'granularity': 'day',
--     },
-- ) }}

-- {% if is_incremental() %}
--     {% set dates = dbt_utils.get_column_values(table=this, column='dt', order_by = 'dt DESC', max_records = 1) %}
--     {% set max_dt = dates[0] %}
-- {% endif %}

WITH
rt_trips AS (
  SELECT
      -- vp_gtfs_dataset_key,
      -- vp_base64_url,
      dt AS service_date,
      schedule_to_use_for_rt_validation_gtfs_dataset_key,
      trip_route_id,
      trip_id AS vp_trip_id
  FROM {{ ref('fct_observed_trips') }}
  WHERE (dt = '2023-02-08' AND vp_num_distinct_message_ids > 0)
),

sched_trips AS(
  SELECT 
    gtfs_dataset_key AS sched_gtfs_dataset_key,
    agency_id,
    name AS sched_gtfs_dataset_name,
    service_date,
    route_id,
    route_short_name,
    trip_id AS sched_trip_id
FROM {{ ref('fct_daily_scheduled_trips') }}
WHERE service_date = '2023-02-08'
),

rt_sched_joined AS (
  SELECT
    T1.sched_gtfs_dataset_key,
    -- T2.vp_gtfs_dataset_key,
    -- T2.vp_base64_url,
    T1.service_date,
    T1.agency_id,
    T1.route_id,
    T2.trip_route_id,
    T1.route_short_name,
    T1.sched_gtfs_dataset_name,
    T1.sched_trip_id,
    T2.vp_trip_id
  FROM sched_trips as T1
  LEFT JOIN rt_trips as T2
    ON
      T1.sched_gtfs_dataset_key = T2.schedule_to_use_for_rt_validation_gtfs_dataset_key
      AND T1.route_id = T2.trip_route_id
      AND T1.sched_trip_id = T2.vp_trip_id
      AND T1.service_date = T2.service_date
  GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
),

gtfs_rt_vs_sched_trips_counts AS (
  SELECT
    T1.sched_gtfs_dataset_key,
    -- T1.vp_gtfs_dataset_key,
    -- T1.vp_base64_url,
    T1.service_date,
    T2.organization_name,
    T1.route_id,
    T1.route_short_name,
    T1.sched_gtfs_dataset_name,
    count(DISTINCT T1.sched_trip_id) AS num_sched_trip_ids,
    count(DISTINCT T1.vp_trip_id) AS num_vp_trip_ids
  FROM rt_sched_joined as T1
    LEFT JOIN {{ ref('dim_provider_gtfs_data') }}  as T2
      ON T1.sched_gtfs_dataset_key = T2.schedule_gtfs_dataset_key
  GROUP BY 1, 2, 3, 4, 5, 6
),

gtfs_scheduled_vs_vehicle_positions AS (
SELECT 
  *,
  num_vp_trip_ids/num_sched_trip_ids AS pct_trips_w_vp
  FROM gtfs_rt_vs_sched_trips_counts
  ORDER BY route_id
)

SELECT *
FROM gtfs_scheduled_vs_vehicle_positions