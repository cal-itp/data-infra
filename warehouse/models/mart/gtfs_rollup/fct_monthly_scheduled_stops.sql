{{ config(materialized='table') }}

WITH stops AS (
    SELECT
        -- get these from dim_stops, since pt_geom can't be grouped or select distinct on
        * EXCEPT(tts_stop_name, pt_geom, parent_station, stop_code,
        stop_name, stop_desc, location_type, wheelchair_boarding)
    FROM {{ ref('fct_daily_scheduled_stops') }}
    WHERE service_date <= LAST_DAY(
        DATE_SUB(CURRENT_DATE("America/Los_Angeles"), INTERVAL 1 MONTH)
    )
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
    -- clustered on feed_key, can we make use to optimize joins?
),


feeds AS (
    SELECT
        feed_key,
        gtfs_dataset_name AS name,
    FROM {{ ref('fct_daily_schedule_feeds') }}
    GROUP BY feed_key, name
),

stops2 AS (
    SELECT
        stops.*,
        feeds.name,

        DATE_TRUNC(service_date, MONTH) AS month_first_day,

        {{ generate_day_type('service_date') }} AS day_type,

    FROM stops
    INNER JOIN feeds
      ON feeds.feed_key = stops.feed_key
),

monthly_stop_counts AS (
    SELECT
        name,
        month_first_day,
        day_type,
        stop_id,

        SUM(daily_arrivals) AS total_stop_arrivals,
        ROUND(SUM(daily_arrivals) / COUNT(DISTINCT service_date), 1) AS daily_stop_arrivals,
        ROUND(AVG(n_hours_in_service), 0) AS n_hours_in_service,

        ROUND(AVG(arrivals_per_hour_owl), 1) AS arrivals_per_hour_owl,
        ROUND(AVG(arrivals_per_hour_early_am), 1) AS arrivals_per_hour_early_am,
        ROUND(AVG(arrivals_per_hour_am_peak), 1) AS arrivals_per_hour_am_peak,
        ROUND(AVG(arrivals_per_hour_midday), 1) AS arrivals_per_hour_midday,
        ROUND(AVG(arrivals_per_hour_pm_peak), 1) AS arrivals_per_hour_pm_peak,
        ROUND(AVG(arrivals_per_hour_evening), 1) AS arrivals_per_hour_evening,

        -- would sum or averages make more sense?
        -- we can always use sum() / n_dates to get average
        -- start with averages, because we want typical metrics over the month
        ROUND(AVG(arrivals_owl), 1) AS arrivals_owl,
        ROUND(AVG(arrivals_early_am), 1) AS arrivals_early_am,
        ROUND(AVG(arrivals_am_peak), 1) AS arrivals_am_peak,
        ROUND(AVG(arrivals_midday), 1) AS arrivals_midday,
        ROUND(AVG(arrivals_pm_peak), 1) AS arrivals_pm_peak,
        ROUND(AVG(arrivals_evening), 1) AS arrivals_evening,

        ROUND(AVG(route_type_0), 1) AS route_type_0,
        ROUND(AVG(route_type_1), 1) AS route_type_1,
        ROUND(AVG(route_type_2), 1) AS route_type_2,
        ROUND(AVG(route_type_3), 1) AS route_type_3,
        ROUND(AVG(route_type_4), 1) AS route_type_4,
        ROUND(AVG(route_type_5), 1) AS route_type_5,
        ROUND(AVG(route_type_6), 1) AS route_type_6,
        ROUND(AVG(route_type_7), 1) AS route_type_7,
        ROUND(AVG(route_type_11), 1) AS route_type_11,
        ROUND(AVG(route_type_12), 1) AS route_type_12,
        ROUND(AVG(missing_route_type), 1) AS missing_route_type,

        -- Ex: a stop for 30 days, with route_type_array = [0, 3] for rail and bus. Output here should get the same, not [0, 3, 0, 3, repeated]
        -- unnest the arrays first then get distinct.
        ARRAY_AGG(DISTINCT route_type ) AS route_type_array,
        ARRAY_AGG(DISTINCT {{ parse_route_id('name', 'route_id') }}) AS route_id_array,
        ARRAY_AGG(DISTINCT
          CASE
            WHEN route_type IN (0, 1, 2) THEN "rail"
            WHEN route_type = 3 THEN "bus"
            WHEN route_type = 4 THEN "ferry"
            WHEN route_type IN (5, 6, 7, 12) THEN "other_rail"
            WHEN route_type = 11 THEN "trolleybus"
          END
        ) AS transit_mode_array,
        COUNT(DISTINCT service_date) AS n_days,
        COUNT(DISTINCT feed_key) AS n_feeds,

    FROM stops2
    LEFT JOIN UNNEST(stops2.route_type_array) AS route_type
    LEFT JOIN UNNEST(stops2.route_id_array) AS route_id
    GROUP BY name, month_first_day, day_type, stop_id
),

most_common_stop_key AS (
    SELECT
        name,
        month_first_day,
        day_type,
        stop_key,
        SUM(daily_arrivals) AS max_stop_arrivals

    FROM stops2
    GROUP BY name, month_first_day, day_type, stop_id, stop_key
    -- dedupe and keep the stop_key with the most arrivals
    -- if multiple stop_keys are found for a gtfs_dataset_name-month_first_day_stop_id
    -- combination (different feed_keys or gtfs_dataset_keys)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               name, month_first_day, day_type, stop_id
                               ORDER BY max_stop_arrivals DESC) = 1
),

fct_monthly_stops AS (
    SELECT
        monthly_stop_counts.name,
        monthly_stop_counts.month_first_day,
        EXTRACT(YEAR FROM monthly_stop_counts.month_first_day) AS year,
        EXTRACT(MONTH FROM monthly_stop_counts.month_first_day) AS month,
        monthly_stop_counts.* EXCEPT(name, month_first_day),
        ARRAY_LENGTH(monthly_stop_counts.route_type_array) AS n_route_types,

        most_common_stop_key.stop_key,

        dim_stops.tts_stop_name,
        dim_stops.pt_geom,
        dim_stops.parent_station,
        dim_stops.stop_code,
        dim_stops.stop_name,
        dim_stops.stop_desc,
        dim_stops.location_type,
        dim_stops.wheelchair_boarding,

    FROM most_common_stop_key
    INNER JOIN dim_stops
        ON most_common_stop_key.stop_key = dim_stops.key
    INNER JOIN monthly_stop_counts
        ON monthly_stop_counts.name = most_common_stop_key.name
        AND monthly_stop_counts.month_first_day = most_common_stop_key.month_first_day
        AND monthly_stop_counts.day_type = most_common_stop_key.day_type
        AND monthly_stop_counts.stop_id = dim_stops.stop_id
)

SELECT * FROM fct_monthly_stops
