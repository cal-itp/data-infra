{{ config(materialized='table') }}

WITH map AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE public_customer_facing_or_regional_subfeed_fixed_route
),
st as (SELECT * from {{ ref('fct_scheduled_trips') }}),
ot as (SELECT * from {{ ref('fct_observed_trips') }}),
fct_daily_trip_updates_vehicle_positions_completeness AS (
  SELECT
    organization_name,
    organization_itp_id,
    organization_source_record_id,
    DATE_TRUNC(st.service_date, DAY) AS service_date,

    -- Percentage of trips with TU messages
    (CAST(SUM(IF(ot.tu_num_distinct_message_ids > 0, 1, 0)) AS FLOAT64) / NULLIF(COUNT(*), 0)) * 100 AS percent_of_trips_with_TU_messages,

    -- Percentage of trips with VP messages
    (CAST(SUM(IF(ot.vp_num_distinct_message_ids > 0, 1, 0)) AS FLOAT64) / NULLIF(COUNT(*), 0)) * 100 AS percent_of_trips_with_VP_messages,
    NULLIF(COUNT(*), 0) as scheduled_trips,
  FROM  st
  LEFT JOIN  ot
    ON st.trip_instance_key = ot.trip_instance_key
  LEFT JOIN  map
    ON map.schedule_feed_key = st.feed_key AND map.date = st.service_date
  WHERE st.service_date < DATE_TRUNC(CURRENT_DATE('America/Los_Angeles'), DAY)
    AND organization_itp_id IS NOT NULL
  GROUP BY 1, 2, 3, 4
)

SELECT *
FROM fct_daily_trip_updates_vehicle_positions_completeness
