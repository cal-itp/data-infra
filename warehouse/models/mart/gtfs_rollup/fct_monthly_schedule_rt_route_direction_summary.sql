{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'schedule_name']
    )
}}

WITH schedule_summary AS (
    SELECT *
    FROM {{ ref('fct_monthly_schedule_route_direction_summary') }}
    -- table; clustered by month_first_day, name
),

rt_summary AS (
    SELECT
        * EXCEPT(month, year)
    FROM {{ ref('fct_monthly_rt_route_direction_summary') }}
    -- clustered by month_first_day, schedule_name
),

route_direction_aggregation AS (
    SELECT
        schedule_summary.*,
        rt_summary.* EXCEPT(n_trips, n_days, month_first_day, day_type, route_name, direction_id),
        rt_summary.n_trips AS n_rt_trips, -- can calculate percent of trips that had RT (tu and/or vp) vs schedule
        rt_summary.n_days AS n_rt_days,

    FROM schedule_summary
    INNER JOIN rt_summary
      ON schedule_summary.month_first_day = rt_summary.month_first_day
      AND schedule_summary.name = rt_summary.schedule_name
      AND schedule_summary.day_type = rt_summary.day_type
      AND schedule_summary.route_name = rt_summary.route_name
      -- in fct_vehicle_locations, when there are nulls, coalesce and fill it in so join works
      AND COALESCE(schedule_summary.direction_id, -1) = COALESCE(rt_summary.direction_id, -1)
)

SELECT * FROM route_direction_aggregation
