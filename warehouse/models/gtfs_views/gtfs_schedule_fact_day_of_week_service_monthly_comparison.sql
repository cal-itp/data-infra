{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_service AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_service') }}
),
day_tot as (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        service_date,
        EXTRACT(DAYOFWEEK from service_date) as metric_day_of_week,
        EXTRACT(MONTH from service_date) as metric_month,
        EXTRACT(YEAR from service_date) as metric_year,
        sum(ttl_service_hours) as ttl_service_hours
    FROM gtfs_schedule_fact_daily_service
    GROUP BY
        calitp_itp_id,
        calitp_url_number,
        service_date
),
monthly_median_by_day_type as (
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
prior_month as (
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
        ) as prior_month,
        LAG(metric_year)
            OVER (
                PARTITION BY
                    calitp_itp_id,
                    calitp_url_number,
                    metric_day_of_week
                ORDER BY
                    metric_year,
                    metric_month
        ) as prior_year,
        LAG(metric_median)
            OVER (
                PARTITION BY
                    calitp_itp_id,
                    calitp_url_number,
                    metric_day_of_week
                ORDER BY
                    metric_year,
                    metric_month
        ) as prior_median
    FROM monthly_median_by_day_type
),
gtfs_schedule_fact_day_of_week_service_monthly_comparison AS (
SELECT *,
    metric_median / prior_median as metric_service_hour_ratio_mom
FROM prior_month
)
SELECT * FROM gtfs_schedule_fact_day_of_week_service_monthly_comparison
