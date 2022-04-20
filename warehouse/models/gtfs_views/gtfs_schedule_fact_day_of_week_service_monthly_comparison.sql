{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_service AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_service') }}
),

day_tot AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        service_date,
        EXTRACT(DAYOFWEEK FROM service_date) AS metric_day_of_week,
        EXTRACT(MONTH FROM service_date) AS metric_month,
        EXTRACT(YEAR FROM service_date) AS metric_year,
        SUM(ttl_service_hours) AS ttl_service_hours
    FROM gtfs_schedule_fact_daily_service
    GROUP BY
        calitp_itp_id,
        calitp_url_number,
        service_date
),

monthly_median_by_day_type AS (
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        metric_year,
        metric_month,
        metric_day_of_week,
        -- median in BQ: https://count.co/sql-resources/bigquery-standard-sql/median
        PERCENTILE_CONT(ttl_service_hours, 0.5)
        OVER (
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                metric_year,
                metric_month,
                metric_day_of_week)
        AS metric_median
    FROM day_tot
),

prior_month AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        metric_year,
        metric_month,
        metric_day_of_week,
        metric_median,
        LAG(metric_month)
        OVER (
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                metric_day_of_week
            ORDER BY
                metric_year,
                metric_month
        ) AS prior_month,
        LAG(metric_year)
        OVER (
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                metric_day_of_week
            ORDER BY
                metric_year,
                metric_month
        ) AS prior_year,
        LAG(metric_median)
        OVER (
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                metric_day_of_week
            ORDER BY
                metric_year,
                metric_month
        ) AS prior_median
    FROM monthly_median_by_day_type
),

gtfs_schedule_fact_day_of_week_service_monthly_comparison AS (
    SELECT
        *,
        metric_median / prior_median AS metric_service_hour_ratio_mom
    FROM prior_month
)

SELECT * FROM gtfs_schedule_fact_day_of_week_service_monthly_comparison
