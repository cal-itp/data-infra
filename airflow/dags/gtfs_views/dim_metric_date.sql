---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.dim_metric_date"

fields:
    period: "The specific range of dates used (e.g. rolling_7, rolling_28, day, month, quarter)"
    period_date: "The date the period describes. For example, rolling_7 goes from period_date to 7 days earlier."
    period_type: "The category of period (rolling, daily, calendar)."
    start_date: "The beginning of the period (inclusive). Note that for daily this is NULL, so data for the same day isn't selected twice."
    end_date: "The end of the period (inclusive). For rolling windows, this is the period_date. For calendar, this is period_date - 1 day (E.g. Jan 1st describes December, etc..)."

tests:
    check_composite_unique:
        - period
        - period_date

dependencies:
    - dim_date
---

WITH
end_dates AS (
    SELECT
        full_date AS period_date
    FROM `views.dim_date`

),

-- rolling ranges (i.e. 7, 28, and 90 day rolling windows)
rolling_ranges AS (
    SELECT
        period
        , period_date
        , "rolling" AS period_type
        , DATE_SUB(period_date, INTERVAL tmp_interval - 1 DAY) AS start_date
        , period_date AS end_date
    FROM end_dates
    CROSS JOIN UNNEST([
        STRUCT("rolling_2" AS period, 2 AS tmp_interval),
        STRUCT("rolling_7" AS period, 7 AS tmp_interval),
        STRUCT("rolling_28" AS period, 28 AS tmp_interval),
        STRUCT("rolling_90" AS period, 90 AS tmp_interval)
        ])
),

-- daily (this can be thought of as a special 1 day rolling window)
period_day AS (

    SELECT
        "day" AS period
        , period_date
        , "daily" AS period_type

        -- setting start date as NULL allows us to filter by daily periods as
        -- if they were rolling ranges. E.g. get just data as it existed on end
        -- date. This is especially useful if you are doing daily + rolling
        -- distinct calculations
        , DATE(NULL) AS start_date
        , period_date AS end_date
    FROM end_dates

),

-- variable frequency: quarterly
period_quarter AS (
    SELECT
        "quarter" AS period

        -- the next period (i.e. this is not inclusive; Jan 1 marks Q4 of the previous year)
        , DATE_ADD(full_date, INTERVAL 1 QUARTER) AS period_date
        , "calendar" AS period_type

        -- range from beginning to end of a quarter
        , full_date AS start_date
        , DATE_SUB(DATE_ADD(full_date, INTERVAL 1 QUARTER), INTERVAL 1 DAY) AS end_date
    FROM `views.dim_date`
    WHERE is_quarter_start
),

-- variable frequency: monthly
period_month AS (
    SELECT
        "month" AS period

        -- the next period (i.e. this is not inclusive; Jan 1 marks Dec of the previous year)
        , DATE_ADD(full_date, INTERVAL 1 MONTH) AS period_date
        , "calendar" AS period_type

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
        , period_date < CURRENT_DATE()
            OR (period_date <= CURRENT_DATE() AND period_type = "calendar")
            AS is_in_past_or_present
    FROM all_periods

)

SELECT
    *
    , is_in_past_or_present AND COALESCE(start_date, "2021-04-15") > "2021-04-15"
        AS is_gtfs_schedule_range
FROM all_periods_enhanced
