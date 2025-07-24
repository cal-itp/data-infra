{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
          'field': 'service_date',
          'data_type': 'date',
          'granularity': 'day'
        },
        cluster_by=['vp_base64_url', 'schedule_feed_key'],
    )
}}

WITH stops_served_vp AS (
    SELECT *
    FROM {{ ref('int_gtfs_rt_vs_sched__stops_served_vehicle_positions') }}
),

stops_grouped AS (
    SELECT
        *,
        CASE
          WHEN meters_to_vp <= 10 THEN TRUE
          ELSE FALSE
        END AS is_near_10m,
        CASE WHEN meters_to_vp <= 25 THEN TRUE
          ELSE FALSE
        END AS is_near_25m,
    FROM stops_served_vp
),

trip_counts_by_group AS (
    SELECT
        vp_base64_url,
        schedule_feed_key,
        schedule_gtfs_dataset_key,
        service_date,
        stop_id,

        COUNTIF(is_near_10m) AS near_10m,
        COUNTIF(is_near_25m) AS near_25m,
        COUNT(*) AS n_vp_trips,

    FROM stops_grouped
    GROUP BY GROUPING SETS(
        vp_base64_url, schedule_feed_key, schedule_gtfs_dataset_key,
        service_date, stop_id,
        is_near_25m, is_near_10m)
    -- grouping set will return the null placeholder
    -- which captures the groups were near_stop_* = false for every stop
),

vp_stop_metrics AS (
    SELECT
        *
    FROM trip_counts_by_group
    WHERE stop_id IS NOT NULL
)

SELECT * FROM vp_stop_metrics
