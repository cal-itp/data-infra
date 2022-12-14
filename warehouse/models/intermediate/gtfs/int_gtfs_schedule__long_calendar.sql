{{ config(materialized='table') }}

-- TODO: make an intermediate calendar and use that instead of the dimension
WITH dim_calendar AS (
    SELECT *
    FROM {{ ref('dim_calendar') }}
),

int_gtfs_schedule__long_calendar AS (
    SELECT
        feed_key,
        {{ dbt_utils.surrogate_key(['feed_key', 'service_id', 'dt']) }} AS key,
        service_id,
        dt AS service_date,
        EXTRACT(DAYOFWEEK FROM dt) AS day_num,
        CASE
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 1 THEN CAST(sunday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 2 THEN CAST(monday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 3 THEN CAST(tuesday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 4 THEN CAST(wednesday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 5 THEN CAST(thursday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 6 THEN CAST(friday AS bool)
            WHEN EXTRACT(DAYOFWEEK FROM dt) = 7 THEN CAST(saturday AS bool)
        END AS service_bool,
        key AS calendar_key
    FROM dim_calendar
    -- one row per day between calendar service start and end date
    -- https://stackoverflow.com/questions/38694040/how-to-generate-date-series-to-occupy-absent-dates-in-google-biqquery/58169269#58169269
    LEFT JOIN UNNEST(GENERATE_DATE_ARRAY(start_date, LEAST(end_date, DATE_ADD(CURRENT_DATE(), INTERVAL 1 YEAR)))) AS dt
)

SELECT *
FROM int_gtfs_schedule__long_calendar
