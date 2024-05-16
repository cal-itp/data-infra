WITH trip_check_cts AS (
    SELECT service_date, COUNT(DISTINCT feed_key) AS trip_n_feeds
    FROM {{ ref('fct_scheduled_trips') }}
    GROUP BY 1
),

-- check that number of feeds that appear in stops is same as trips
stop_check_cts AS (
    SELECT service_date, COUNT(DISTINCT feed_key) AS stop_n_feeds
    FROM {{ ref('fct_daily_scheduled_stops') }}
    GROUP BY 1
),

check_cts AS (
    SELECT
        trip_check_cts.service_date,
        trip_n_feeds,
        stop_n_feeds,
        stop_n_feeds / trip_n_feeds AS ratio
    FROM trip_check_cts
    LEFT JOIN stop_check_cts
        ON trip_check_cts.service_date = stop_check_cts.service_date
    ORDER BY service_date DESC --noqa: AM06
)

SELECT *
FROM check_cts
WHERE ratio < 0.75
