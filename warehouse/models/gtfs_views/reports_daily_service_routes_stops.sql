{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_service AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_service') }}
),

gtfs_schedule_fact_daily_feed_stops AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_feed_stops') }} 
),

gtfs_schedule_fact_daily_feed_routes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_feed_routes') }} 
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
),

reports_gtfs_schedule_index AS (
    SELECT *
    FROM {{ ref('reports_gtfs_schedule_index') }} 
),

stops_agg AS (
    SELECT
        feed_key,
        date AS service_date,
        COUNT(DISTINCT stop_key) AS n_stops
    FROM gtfs_schedule_fact_daily_feed_stops
    -- temporary, test filter
    WHERE date >= '2022-05-01' AND date <= '2022-06-30'
    GROUP BY 1, 2
),

routes_agg AS (
    SELECT
        feed_key,
        date AS service_date,
        COUNT(DISTINCT route_key) AS n_routes
    FROM gtfs_schedule_fact_daily_feed_routes
    -- temporary, test filter
    WHERE date >= '2022-05-01' AND date <= '2022-06-30'
    GROUP BY 1, 2
),

stops_routes_agg AS (
    SELECT
        T1.feed_key,
        T1.n_stops,
        T1.service_date,
        T2.n_routes,
    FROM stops_agg AS T1
    INNER JOIN routes_agg AS T2
        ON T1.service_date = T2.service_date
            AND T1.feed_key = T2.feed_key
),

stops_routes_metadata_joined AS (
    SELECT
        T1.*,
        T2.calitp_itp_id,
        T2.calitp_url_number,
    FROM stops_routes_agg AS T1
    INNER JOIN gtfs_schedule_dim_feeds AS T2
        ON T1.feed_key = T2.feed_key
),

date_renamed AS (
    SELECT full_date AS service_date
    FROM dim_date
    -- temporary, test filter
    WHERE full_date >= '2022-05-01' AND full_date <= '2022-06-30'
),

reports_feeds_distinct AS (
    SELECT DISTINCT calitp_itp_id, calitp_url_number, use_for_report
    FROM reports_gtfs_schedule_index
),

date_feed_cross AS (
    SELECT
        T1.service_date,
        DATE_ADD(LAST_DAY(T1.service_date, MONTH), INTERVAL 1 DAY) AS publish_date,
        -- construct publish_date for all combinations to filter later
        T2.calitp_itp_id,
        T2.calitp_url_number,
    FROM date_renamed AS T1
    CROSS JOIN reports_feeds_distinct AS T2
    WHERE T2.use_for_report
    -- temporary, for testing on a single month...
    AND T1.service_date >= '2022-05-01' AND T1.service_date <= '2022-06-30'
),

for_report AS (
    SELECT
    calitp_itp_id,
    calitp_url_number,
    date_start,
    date_end,
    publish_date
    FROM reports_gtfs_schedule_index
    WHERE use_for_report
),

date_feed_cross_rejoin AS (
    SELECT
    T1.*
    FROM date_feed_cross AS T1
    INNER JOIN for_report AS T2
    ON T1.publish_date = T2.publish_date
        AND T1.calitp_itp_id = T2.calitp_itp_id
        AND T1.calitp_url_number = T2.calitp_url_number
),

service_agg AS (
    SELECT
        T1.service_date,
        T1.calitp_itp_id,
        T1.calitp_url_number,
        T2.feed_key,
        SUM(T2.ttl_service_hours) AS ttl_service_hours,
        SUM(T2.n_trips) AS n_trips,
        MIN(T2.first_departure_ts) AS first_departure_ts,
        MAX(T2.last_arrival_ts) AS last_arrival_ts
    FROM date_feed_cross_rejoin AS T1
    LEFT JOIN gtfs_schedule_fact_daily_service AS T2
        ON T1.service_date = T2.service_date
            AND T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
   GROUP BY 1, 2, 3, 4
),

reports_daily_service_routes_stops AS (
    SELECT
        T1.*,
        T2.n_stops,
        T2.n_routes,
    FROM service_agg AS T1
    INNER JOIN stops_routes_metadata_joined AS T2
        ON T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.service_date = T2.service_date
) 

SELECT * FROM reports_daily_service_routes_stops
