{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'name']
    )
}}

WITH trips AS (
    SELECT *
    FROM {{ ref('fct_scheduled_trips') }}
    WHERE service_date >= "2025-01-01" AND service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
    -- table; clustered by service_date'
),

time_of_day_counts AS (
    SELECT
        name,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        {{ generate_day_type('service_date') }} AS day_type,
        time_of_day,
        LOWER(REPLACE(time_of_day, " ", "_")) AS time_of_day_cleaned,
        {{ get_combined_route_name('name', 'route_id', 'route_short_name', 'route_long_name') }} AS route_name,
        direction_id,

        -- columns needed for frequency calculations
        COUNT(DISTINCT trip_instance_key) / COUNT(DISTINCT service_date) AS daily_trips,
        SUM(num_stop_times) / COUNT(DISTINCT service_date) AS daily_stop_arrivals,
        SUM(num_distinct_stops_served) / COUNT(DISTINCT service_date) AS daily_distinct_stops, -- 2 different trips for same route-dir can have different number of stops (express vs long trips)
        {{ generate_time_of_day_hours('time_of_day') }} AS n_hours,
        COUNT(DISTINCT service_date) AS n_days,

        -- columns needed for route aggregation generally
        SUM(service_hours) AS service_hours,
        SUM(flex_service_hours) AS flex_service_hours,

    FROM trips
    GROUP BY 1, 2, 3, 4, 5, 6, 7

),

pivoted_timeofday AS (
    SELECT *
    FROM (
        SELECT
            name,
            month_first_day,
            day_type,
            route_name,
            direction_id,

            time_of_day_cleaned,
            daily_trips,
            n_hours
        FROM time_of_day_counts
    )
    PIVOT(
        MIN(daily_trips) AS daily_trips,
        MIN(daily_trips / n_hours) AS frequency
        FOR time_of_day_cleaned IN
        ("owl", "early_am", "am_peak", "midday", "pm_peak", "evening")
    )
),

all_day_counts AS (
    SELECT
        name,
        month_first_day,
        day_type,
        route_name,
        direction_id,

        SUM(daily_trips) AS daily_trips_all_day,
        SUM(daily_stop_arrivals) AS daily_stop_arrivals_all_day,
        SUM(daily_distinct_stops) AS daily_distinct_stops_all_day,
        ROUND(SUM(daily_trips) / SUM(n_hours), 2) AS frequency_all_day,

        -- if service runs for 1 hr a day, for weekdays, it's 5 hours; for Sat, it's 1 hr
        -- to compare weekday/Sat/Sun service, we would normalize by day
        SUM(service_hours) / AVG(n_days) AS daily_service_hours,
        SUM(flex_service_hours) / AVG(n_days) AS daily_flex_service_hours,

    FROM time_of_day_counts
    GROUP BY 1, 2, 3, 4, 5
),

deduped_route_types AS (
    SELECT
        name,
        {{ get_combined_route_name('name', 'route_id', 'route_short_name', 'route_long_name') }} AS route_name,
        route_type,
        route_color,
    FROM trips
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY name, route_name
        ORDER BY service_date DESC
    ) = 1
),

route_direction_aggregation AS (
    SELECT
        all_day_counts.name,
        all_day_counts.month_first_day,
        EXTRACT(MONTH FROM all_day_counts.month_first_day) AS month,
        EXTRACT(YEAR FROM all_day_counts.month_first_day) AS year,
        all_day_counts.day_type,
        all_day_counts.route_name,
        all_day_counts.direction_id,
        deduped_route_types.route_type,
        deduped_route_types.route_color,
        -- get what we can based on route name to separate our bus types
        -- https://github.com/cal-itp/data-analyses/blob/dd3b5f963bfa480fb949c5949bea6485431361fe/gtfs_funnel/nacto_utils.py#L24-L58
        CASE
            WHEN route_type = "0" OR route_type = "1" OR route_type = "2" THEN "rail"
            WHEN route_type = "4" THEN "ferry"
            WHEN (
                CONTAINS_SUBSTR(all_day_counts.route_name, "Express")
                OR CONTAINS_SUBSTR(all_day_counts.route_name, "Limited")
            ) AND route_type = "3" THEN "express"
            WHEN CONTAINS_SUBSTR(all_day_counts.route_name, "Rapid") AND route_type = "3" THEN "rapid"
            WHEN route_type = "3" THEN "bus"
            ELSE "unknown"
        END AS route_typology,

        daily_trips_all_day,
        daily_stop_arrivals_all_day,
        daily_distinct_stops_all_day,
        frequency_all_day,
        daily_service_hours,
        daily_flex_service_hours,

        daily_trips_owl,
        daily_trips_early_am,
        daily_trips_am_peak,
        daily_trips_midday,
        daily_trips_pm_peak,
        daily_trips_evening,
        daily_trips_am_peak + daily_trips_pm_peak AS daily_trips_peak,
        daily_trips_all_day - (daily_trips_am_peak + daily_trips_pm_peak) AS daily_trips_offpeak,

        ROUND(frequency_owl, 2) AS frequency_owl,
        ROUND(frequency_early_am, 2) AS frequency_early_am,
        ROUND(frequency_am_peak, 2) AS frequency_am_peak,
        ROUND(frequency_midday, 2) AS frequency_midday,
        ROUND(frequency_pm_peak, 2) AS frequency_pm_peak,
        ROUND(frequency_evening, 2) AS frequency_evening,
        -- calculate frequency for peak/offpeak this way by weighting the hours present in each category
        ROUND(
          (frequency_am_peak * 3 + frequency_pm_peak * 5) / 8,
          2) AS frequency_peak,
        ROUND(
          (frequency_owl * 4 + frequency_early_am * 3
          + frequency_midday * 5 + frequency_evening * 4) / 16,
          2) AS frequency_offpeak,

    FROM all_day_counts
    INNER JOIN pivoted_timeofday
        ON all_day_counts.name = pivoted_timeofday.name
        AND all_day_counts.month_first_day = pivoted_timeofday.month_first_day
        AND all_day_counts.day_type = pivoted_timeofday.day_type
        AND all_day_counts.route_name = pivoted_timeofday.route_name
        AND COALESCE(all_day_counts.direction_id, -1) = COALESCE(pivoted_timeofday.direction_id, -1)
    INNER JOIN deduped_route_types
        ON all_day_counts.name = deduped_route_types.name
        AND all_day_counts.route_name = deduped_route_types.route_name
)

SELECT * FROM route_direction_aggregation
