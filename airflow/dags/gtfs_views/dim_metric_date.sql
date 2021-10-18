---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.dim_metric_date"

fields:
    metric_period: "The specific range of dates used (e.g. rolling_7, rolling_28, day, month, quarter)"
    metric_date: "The date the metric_period describes. For example, rolling_7 goes from metric_date to 7 days earlier."
    metric_type: "The category of metric_period (rolling, daily, calendar)."
    start_date: "The beginning of the metric_period (inclusive). Note that for daily this is NULL, so data for the same day isn't selected twice."
    end_date: "The end of the metric_period (inclusive). For rolling windows, this is the metric_date. For calendar, this is metric_date - 1 day (E.g. Jan 1st describes December, etc..)."

tests:
    check_composite_unique:
        - metric_period
        - metric_date

dependencies:
    - dim_date
---

WITH
end_dates AS (
    SELECT
        full_date AS metric_date
    FROM `views.dim_date`

),

-- rolling ranges (i.e. 7, 28, and 90 day rolling windows)
rolling_ranges AS (
    SELECT
        metric_period
        , metric_date
        , "rolling" AS metric_type
        , DATE_SUB(metric_date, INTERVAL tmp_interval - 1 DAY) AS start_date
        , metric_date AS end_date
    FROM end_dates
    CROSS JOIN UNNEST([
        STRUCT("rolling_2" AS metric_period, 2 AS tmp_interval),
        STRUCT("rolling_7" AS metric_period, 7 AS tmp_interval),
        STRUCT("rolling_28" AS metric_period, 28 AS tmp_interval),
        STRUCT("rolling_90" AS metric_period, 90 AS tmp_interval)
        ])
),

-- daily (this can be thought of as a special 1 day rolling window)
period_day AS (

    SELECT
        "day" AS metric_period
        , metric_date
        , "daily" AS metric_type

        -- setting start date as NULL allows us to filter by daily periods as
        -- if they were rolling ranges. E.g. get just data as it existed on end
        -- date. This is especially useful if you are doing daily + rolling
        -- distinct calculations
        , DATE(NULL) AS start_date
        , metric_date AS end_date
    FROM end_dates

),

-- variable frequency: quarterly
period_quarter AS (
    SELECT
        "quarter" AS metric_period

        -- the next period (i.e. this is not inclusive; Jan 1 marks Q4 of the previous year)
        , DATE_ADD(full_date, INTERVAL 1 QUARTER) AS metric_date
        , "calendar" AS metric_type

        -- range from beginning to end of a quarter
        , full_date AS start_date
        , DATE_SUB(DATE_ADD(full_date, INTERVAL 1 QUARTER), INTERVAL 1 DAY) AS end_date
    FROM `views.dim_date`
    WHERE is_quarter_start
),

-- variable frequency: monthly
period_month AS (
    SELECT
        "month" AS metric_period

        -- the next period (i.e. this is not inclusive; Jan 1 marks Dec of the previous year)
        , DATE_ADD(full_date, INTERVAL 1 MONTH) AS metric_date
        , "calendar" AS metric_type

        -- range from beginning to end of a month
        , full_date AS start_date
        , DATE_SUB(DATE_ADD(full_date, INTERVAL 1 MONTH), INTERVAL 1 DAY) AS end_date
    FROM `views.dim_date`
    WHERE is_month_start
),

all_periods AS (

    SELECT * FROM rolling_ranges
    UNION ALL
    SELECT * FROM period_day
    UNION ALL
    SELECT * FROM period_month
    UNION ALL
    SELECT * FROM period_quarter

),

all_periods_enhanced AS (

    SELECT
        *
        , metric_date < CURRENT_DATE()
            OR (metric_date <= CURRENT_DATE() AND metric_type = "calendar")
            AS is_in_past_or_present
    FROM all_periods

)

SELECT
    *
    , is_in_past_or_present AND COALESCE(start_date, "2021-04-15") > "2021-04-15"
        AS is_gtfs_schedule_range
FROM all_periods_enhanced
