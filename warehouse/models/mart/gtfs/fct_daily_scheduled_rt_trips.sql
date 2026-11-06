{{
    config(
        materialized='view',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day'
        },
        cluster_by=['schedule_gtfs_dataset_key', 'schedule_name'],
    )
}}

WITH schedule_trips AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips`--{{ ref('fct_scheduled_trips') }}
    WHERE service_date >= "2026-10-01"
),

observed_trips AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips`--{{ ref('fct_observed_trips') }}
    WHERE service_date >= "2026-10-01"
),

schedule_rt_trips AS (
    SELECT
        COALESCE(schedule_trips.service_date, observed_trips.service_date) AS service_date,
        COALESCE(schedule_trips.gtfs_dataset_key, observed_trips.schedule_gtfs_dataset_key) AS schedule_gtfs_dataset_key,
        COALESCE(schedule_trips.name, observed_trips.schedule_name) AS schedule_name,
        COALESCE(schedule_trips.base64_url, observed_trips.schedule_base64_url) AS schedule_base64_url,
        observed_trips.vp_name,
        observed_trips.tu_name,
        observed_trips.appeared_in_vp,
        observed_trips.appeared_in_tu,

        COALESCE(schedule_trips.trip_instance_key, observed_trips.trip_instance_key) AS trip_instance_key,
        schedule_trips.trip_instance_key IS NULL AS in_rt_only,
        observed_trips.trip_instance_key IS NULL AS in_sched_only,
        IF(schedule_trips.trip_instance_key = observed_trips.trip_instance_key, TRUE, FALSE) AS in_both,

        -- rest of scheduled trips columns, get counts or totals
        {{ get_combined_route_name('schedule_trips.name', 'route_id', 'route_short_name', 'route_long_name') }} AS route_name,
        schedule_trips.* EXCEPT(service_date, gtfs_dataset_key, name, base64_url, trip_instance_key),

        -- rest of observed trips columns, get counts or totals
        observed_trips.* EXCEPT(service_date, schedule_gtfs_dataset_key, schedule_name, schedule_base64_url, trip_instance_key, vp_name, tu_name, appeared_in_vp, appeared_in_tu, trip_id, iteration_num),

    FROM schedule_trips
    FULL OUTER JOIN observed_trips
        ON schedule_trips.service_date = observed_trips.service_date
        AND schedule_trips.gtfs_dataset_key = observed_trips.schedule_gtfs_dataset_key
        AND schedule_trips.trip_instance_key = observed_trips.trip_instance_key
)

SELECT * FROM schedule_rt_trips
