---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_fact_day_of_week_service_monthly_comparison"

description: Compares the median total service hours for a given ITP ID + URL + day of the week to the last available month to identify anomalies.


fields:
    calitp_itp_id: ITP ID
    calitp_url_number: URL number
    metric_year: The year of the month for which the month-over-month ratio is being calculated
    metric_month: The month for which the month-over-month ratio is being calculated
    metric_day_of_week: The day of the week for which the ratio is calculated; 1 = Sunday (from BigQuery date standard)
    metric_median: Median total service hours (across all service_id values, calculated from gtfs_schedule_fact_daily_service)
    prior_month: The prior month against which the current month is being compared; months may not be consecutive if there was no service for a given day of the week in a given month (so, if there is data for August and none again until November, the November data will be compared to August)
    prior_year: The year of the prior month against which the current month is being compared
    metric_service_hour_ratio_mom: metric_median for the current month divided by metric_median for the prior month

tests:
  check_null:
    - calitp_itp_id
    - calitp_url_number
    - metric_day_of_week
    - metric_month
    - metric_year

  check_composite_unique:
    - calitp_itp_id
    - calitp_url_number
    - metric_day_of_week
    - metric_year
    - metric_month

dependencies:
  - gtfs_schedule_fact_daily_service
---

WITH
day_tot as (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        service_date,
        EXTRACT(DAYOFWEEK from service_date) as metric_day_of_week,
        EXTRACT(MONTH from service_date) as metric_month,
        EXTRACT(YEAR from service_date) as metric_year,
        sum(ttl_service_hours) as ttl_service_hours
    FROM `cal-itp-data-infra.views.gtfs_schedule_fact_daily_service`
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
    last_month as (
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
            ) as prior_year
        FROM monthly_median_by_day_type
    )

SELECT t1.*,
    t1.metric_median / t2.metric_median as metric_service_hour_ratio_mom
FROM last_month t1
LEFT JOIN last_month t2
    ON t1.prior_month = t2.metric_month
    AND t1.prior_year = t2.metric_year
    AND t1.calitp_itp_id = t2.calitp_itp_id
    AND t1.calitp_url_number = t2.calitp_url_number
    AND t1.metric_day_of_week = t2.metric_day_of_week
