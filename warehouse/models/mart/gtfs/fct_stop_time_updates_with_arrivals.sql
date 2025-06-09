WITH fct_stop_time_updates AS (
    SELECT
        base64_url,
        service_date,
        trip_id,
        trip_start_date,
        trip_start_time,
        stop_id,
        _extract_ts, -- this is UTC
        --trip_update_timestamp,
        --header_timestamp,
        arrival_time,
        departure_time,
    FROM {{ ref('fct_stop_time_updates') }}
),

fct_stop_arrivals AS (
    SELECT DISTINCT
        base64_url,
        service_date,
        trip_id,
        stop_id,
        actual_arrival_pacific,
        actual_arrival,

    FROM {{ ref('fct_stop_time_arrivals') }}
),

stop_times_with_arrivals AS (
  SELECT
    tu.base64_url,
    tu.service_date,
    tu.trip_id,
    tu.trip_start_date,
    tu.trip_start_time,
    tu.stop_id,
    tu._extract_ts,
    EXTRACT(HOUR FROM tu._extract_ts) AS extract_hour,
    EXTRACT(MINUTE FROM tu._extract_ts) AS extract_minute,
    TIMESTAMP_SECONDS(tu.arrival_time) AS arrival_time, -- turn posix time into UTC
    TIMESTAMP_SECONDS(tu.departure_time) AS departure_time, -- turn posix time into UTC

    arrivals.actual_arrival_pacific,
    arrivals.actual_arrival,

  FROM fct_stop_time_updates as tu
  INNER JOIN fct_stop_arrivals as arrivals
    ON tu.base64_url = arrivals.base64_url
      AND tu.service_date = arrivals.service_date
      AND tu.trip_id = arrivals.trip_id
      AND tu.stop_id = arrivals.stop_id
      -- removed the trip_start_date/time from this and it merged better?
      -- with trip_start_date/time, somehow the merge dropped all the rows (incremental tables loaded locally?)
)

SELECT * FROM stop_times_with_arrivals
