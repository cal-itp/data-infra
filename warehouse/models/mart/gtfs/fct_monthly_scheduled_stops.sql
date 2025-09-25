{{
    config(
        materialized='table',
        cluster_by=['month_first_day', 'name']
    )
}}

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
    SELECT DISTINCT
        feed_key,
        gtfs_dataset_name AS name,
    FROM {{ ref('fct_daily_schedule_feeds') }}
),

stops2 AS (
    SELECT
        stops.*,
        feeds.name,

        EXTRACT(month FROM service_date) AS month,
        EXTRACT(year FROM service_date) AS year,
        DATE_TRUNC(service_date, MONTH) AS month_first_day,

        {{ generate_day_type('service_date') }} AS day_type,

    FROM stops
    INNER JOIN feeds
      ON feeds.feed_key = stops.feed_key
),

monthly_stop_counts AS (
    SELECT
        name,
        year,
        month,
        month_first_day,
        day_type,
        stop_id,

        SUM(stop_event_count) AS ttl_stop_event_count,

        SUM(route_type_0) AS route_type_0,
        SUM(route_type_1) AS route_type_1,
        SUM(route_type_2) AS route_type_2,
        SUM(route_type_3) AS route_type_3,
        SUM(route_type_4) AS route_type_4,
        SUM(route_type_5) AS route_type_5,
        SUM(route_type_6) AS route_type_6,
        SUM(route_type_7) AS route_type_7,
        SUM(route_type_11) AS route_type_11,
        SUM(route_type_12) AS route_type_12,
        SUM(missing_route_type) AS missing_route_type,

        COUNT(DISTINCT service_date) AS n_days,
        COUNT(DISTINCT feed_key) AS n_feeds,

    FROM stops2
    GROUP BY name, year, month, month_first_day, day_type, stop_id
),

most_common_stop_key AS (
    SELECT
        name,
        month_first_day,
        day_type,
        stop_key,
        SUM(stop_event_count) AS max_stop_events

    FROM stops2
    GROUP BY name, month_first_day, day_type, stop_id, stop_key
    -- dedupe and keep the stop_key with the most stop_events
    -- if multiple stop_keys are found for a gtfs_dataset_name-month_first_day_stop_id
    -- combination (different feed_keys or gtfs_dataset_keys)
    QUALIFY ROW_NUMBER() OVER (PARTITION BY
                               name, month_first_day, day_type, stop_id
                               ORDER BY max_stop_events DESC) = 1
),

fct_monthly_stops AS (
    SELECT
        monthly_stop_counts.*,
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
