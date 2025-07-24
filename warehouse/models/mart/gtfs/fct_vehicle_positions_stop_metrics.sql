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

trip_counts_by_group AS (
    SELECT
        vp_base64_url,
        schedule_feed_key,
        schedule_gtfs_dataset_key,
        service_date,

        stop_id,

        COUNTIF(near_stop_50m) AS near_50m,
        COUNTIF(near_stop_25m) AS near_25m,
        COUNTIF(near_stop_10m) AS near_10m,
        COUNT(*) AS n_vp_trips,

    FROM stops_served_vp
    GROUP BY GROUPING SETS(
        vp_base64_url, schedule_feed_key, schedule_gtfs_dataset_key,
        service_date, stop_id,
        near_stop_50m, near_stop_25m, near_stop_10m)
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
