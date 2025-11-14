{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'schedule_name']
    )
}}

WITH observed_trips AS (
    SELECT *
    FROM `cal-itp-data-infra.mart_gtfs.fct_observed_trips` --{{ ref('fct_observed_trips') }}
    WHERE service_date >= "2025-01-01" AND service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
    -- incremental; partitioned by service_date
    -- clustered by service_date, schedule_base64_url
),

scheduled_trips AS (
    SELECT
        service_date,
        base64_url,
        trip_instance_key,
        {{ get_combined_route_name('name', 'route_id', 'route_short_name', 'route_long_name') }} AS route_name,
        direction_id,

    FROM `cal-itp-data-infra.mart_gtfs.fct_scheduled_trips` -- {{ ref('fct_scheduled_trips') }}
    WHERE service_date >= "2025-01-01" AND service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
    -- table; clustered by service_date'
),

route_direction_aggregation AS (
    SELECT
        EXTRACT(month FROM observed_trips.service_date) AS month,
        EXTRACT(year FROM observed_trips.service_date) AS year,
        DATE_TRUNC(observed_trips.service_date, MONTH) AS month_first_day,
        {{ generate_day_type('observed_trips.service_date') }} AS day_type,

        -- identifiers
        observed_trips.schedule_base64_url,
        observed_trips.tu_name,
        observed_trips.vp_name,
        observed_trips.schedule_name,
        observed_trips.tu_base64_url,
        observed_trips.vp_base64_url,

        -- route direction columns
        scheduled_trips.route_name,
        scheduled_trips.direction_id,

        -- metrics from trip updates
        SUM(observed_trips.tu_num_distinct_updates) AS tu_num_distinct_updates,
        SUM(observed_trips.tu_num_distinct_updates) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_num_distinct_updates, -- check column naming pattern for daily avg
        SUM(observed_trips.tu_num_skipped_stops) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_num_skipped_stops,
        SUM(observed_trips.tu_num_canceled_stops) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_num_canceled_stops,
        SUM(observed_trips.tu_num_added_stops) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_num_added_stops,
        SUM(observed_trips.tu_num_scheduled_stops) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_num_scheduled_stops,
        COUNTIF(appeared_in_tu IS TRUE) AS n_tu_trips, -- total number of weekday trips with trip updates
        COUNTIF(appeared_in_tu IS TRUE) / COUNT(DISTINCT observed_trips.service_date) AS daily_tu_trips, -- the average number of weekday trips with trip updates

        -- metrics from vehicle positions
        SUM(observed_trips.vp_num_distinct_updates) AS vp_num_distinct_updates,
        SUM(observed_trips.vp_num_distinct_updates) / COUNT(DISTINCT observed_trips.service_date) AS daily_vp_num_distinct_updates,
        COUNTIF(appeared_in_vp IS TRUE) AS n_vp_trips,
        COUNTIF(appeared_in_vp IS TRUE) / COUNT(DISTINCT observed_trips.service_date) AS daily_vp_trips,

        COUNT(DISTINCT observed_trips.trip_instance_key) AS n_trips,
        COUNT(DISTINCT observed_trips.service_date) AS n_days,

    FROM observed_trips
    INNER JOIN scheduled_trips
      ON observed_trips.service_date = scheduled_trips.service_date
      AND observed_trips.schedule_base64_url = scheduled_trips.base64_url
      AND observed_trips.trip_instance_key = scheduled_trips.trip_instance_key
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
)

SELECT * FROM route_direction_aggregation
