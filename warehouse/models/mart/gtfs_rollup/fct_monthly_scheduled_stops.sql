{{ config(materialized='table') }}

WITH monthly_stops AS (
    SELECT
        feeds.gtfs_dataset_name AS name,

        DATE_TRUNC(service_date, MONTH) AS month_first_day,
        EXTRACT(YEAR FROM service_date) AS year,
        EXTRACT(MONTH FROM service_date) AS month,
        {{ generate_day_type('service_date') }} AS day_type,

        stops.stop_id,
        stops.stop_key,

        COUNT(DISTINCT service_date) AS n_days,
        COUNT(DISTINCT stops.feed_key) AS n_feeds,

        SUM(daily_arrivals) AS total_stop_arrivals,
        ROUND(SUM(daily_arrivals) / COUNT(DISTINCT service_date), 1) AS daily_stop_arrivals,

        SUM(n_hours_in_service) AS total_n_hours_in_service,
        ROUND(AVG(n_hours_in_service), 0) AS daily_n_hours_in_service,

        ROUND(AVG(arrivals_per_hour_owl), 1) AS daily_arrivals_per_hour_owl,
        ROUND(AVG(arrivals_per_hour_early_am), 1) AS daily_arrivals_per_hour_early_am,
        ROUND(AVG(arrivals_per_hour_am_peak), 1) AS daily_arrivals_per_hour_am_peak,
        ROUND(AVG(arrivals_per_hour_midday), 1) AS daily_arrivals_per_hour_midday,
        ROUND(AVG(arrivals_per_hour_pm_peak), 1) AS daily_arrivals_per_hour_pm_peak,
        ROUND(AVG(arrivals_per_hour_evening), 1) AS daily_arrivals_per_hour_evening,

        SUM(arrivals_owl) AS total_arrivals_owl,
        SUM(arrivals_early_am) AS total_arrivals_early_am,
        SUM(arrivals_am_peak) AS total_arrivals_am_peak,
        SUM(arrivals_midday) AS total_arrivals_midday,
        SUM(arrivals_pm_peak) AS total_arrivals_pm_peak,
        SUM(arrivals_evening) AS total_arrivals_evening,

        SUM(route_type_0) AS total_route_type_0,
        SUM(route_type_1) AS total_route_type_1,
        SUM(route_type_2) AS total_route_type_2,
        SUM(route_type_3) AS total_route_type_3,
        SUM(route_type_4) AS total_route_type_4,
        SUM(route_type_5) AS total_route_type_5,
        SUM(route_type_6) AS total_route_type_6,
        SUM(route_type_7) AS total_route_type_7,
        SUM(route_type_11) AS total_route_type_11,
        SUM(route_type_12) AS total_route_type_12,
        SUM(missing_route_type) AS total_missing_route_type,

        ROUND(AVG(route_type_0), 1) AS daily_route_type_0,
        ROUND(AVG(route_type_1), 1) AS daily_route_type_1,
        ROUND(AVG(route_type_2), 1) AS daily_route_type_2,
        ROUND(AVG(route_type_3), 1) AS daily_route_type_3,
        ROUND(AVG(route_type_4), 1) AS daily_route_type_4,
        ROUND(AVG(route_type_5), 1) AS daily_route_type_5,
        ROUND(AVG(route_type_6), 1) AS daily_route_type_6,
        ROUND(AVG(route_type_7), 1) AS daily_route_type_7,
        ROUND(AVG(route_type_11), 1) AS daily_route_type_11,
        ROUND(AVG(route_type_12), 1) AS daily_route_type_12,
        ROUND(AVG(missing_route_type), 1) AS daily_missing_route_type,

        -- Ex: a stop for 30 days, with route_type_array = [0, 3] for rail and bus.
        -- Output here should get the same, not [0, 3, 0, 3, repeated] - DISTINCT applied on final query
        ARRAY_CONCAT_AGG(route_id_array) AS route_id_array,
        ARRAY_CONCAT_AGG(route_type_array) AS route_type_array,
        ARRAY_CONCAT_AGG(transit_mode_array) AS transit_mode_array

    FROM {{ ref('fct_daily_scheduled_stops') }} AS stops
    INNER JOIN {{ ref('fct_daily_schedule_feeds') }} AS feeds
       ON feeds.feed_key = stops.feed_key
      AND feeds.date = DATE_TRUNC(service_date, MONTH)
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

fct_monthly_scheduled_stops AS (
    SELECT
        monthly_stops.* EXCEPT(route_type_array, route_id_array, transit_mode_array),

        ARRAY(SELECT DISTINCT route_type FROM UNNEST(monthly_stops.route_type_array) AS route_type ORDER BY 1) AS route_type_array,
        ARRAY(SELECT DISTINCT route_id FROM UNNEST(monthly_stops.route_id_array) AS route_id ORDER BY 1) AS route_id_array,
        ARRAY(SELECT DISTINCT transit_mode FROM UNNEST(monthly_stops.transit_mode_array) AS transit_mode ORDER BY 1) AS transit_mode_array,

        dim_stops.tts_stop_name,
        dim_stops.pt_geom,
        dim_stops.parent_station,
        dim_stops.stop_code,
        dim_stops.stop_name,
        dim_stops.stop_desc,
        dim_stops.location_type,
        dim_stops.wheelchair_boarding

    FROM monthly_stops
    INNER JOIN {{ ref('dim_stops') }} AS dim_stops
       ON monthly_stops.stop_key = dim_stops.key
)

SELECT
    name,

    month_first_day,
    `year`,
    `month`,
    day_type,

    stop_id,

    total_stop_arrivals,
    daily_stop_arrivals,

    total_n_hours_in_service,
    daily_n_hours_in_service,

    daily_arrivals_per_hour_owl,
    daily_arrivals_per_hour_early_am,
    daily_arrivals_per_hour_am_peak,
    daily_arrivals_per_hour_midday,
    daily_arrivals_per_hour_pm_peak,
    daily_arrivals_per_hour_evening,

    total_arrivals_owl,
    total_arrivals_early_am,
    total_arrivals_am_peak,
    total_arrivals_midday,
    total_arrivals_pm_peak,
    total_arrivals_evening,

    total_route_type_0,
    total_route_type_1,
    total_route_type_2,
    total_route_type_3,
    total_route_type_4,
    total_route_type_5,
    total_route_type_6,
    total_route_type_7,
    total_route_type_11,
    total_route_type_12,
    total_missing_route_type,

    daily_route_type_0,
    daily_route_type_1,
    daily_route_type_2,
    daily_route_type_3,
    daily_route_type_4,
    daily_route_type_5,
    daily_route_type_6,
    daily_route_type_7,
    daily_route_type_11,
    daily_route_type_12,
    daily_missing_route_type,

    route_type_array,
    route_id_array,
    transit_mode_array,

    ARRAY_LENGTH(route_type_array) AS n_route_types,

    n_days,
    n_feeds,

    stop_key,
    tts_stop_name,
    pt_geom,
    parent_station,
    stop_code,
    stop_name,
    stop_desc,
    location_type,
    wheelchair_boarding

FROM fct_monthly_scheduled_stops
