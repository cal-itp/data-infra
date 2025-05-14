{{ config(materialized='table') }}


WITH trips AS (
    SELECT DISTINCT
        name,
        base64_url,
        year,
        route_short_name,
        route_long_name,
    FROM cal-itp-data-infra-staging.tiffany_mart_gtfs.trips_monthly
),

route_counts AS (
    SELECT
        trips.*,
        CONCAT(COALESCE(trips.route_short_name, trips.route_long_name, ""), ' ') AS route_name
    FROM trips
),

fct_annual_feed_summary AS (
    SELECT
        route_counts.name,
        route_counts.base64_url,
        route_counts.year,
        COUNT(DISTINCT route_counts.route_name) AS n_routes,
    FROM route_counts
    GROUP BY 1, 2, 3
)

SELECT * FROM fct_annual_feed_summary
