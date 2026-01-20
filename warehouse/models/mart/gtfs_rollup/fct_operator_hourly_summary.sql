{{ config(materialized='table') }}

-- scheduled trips: n_trips that started that hour for GTFS digest
-- scheduled stop times: aggregate stop arrivals by hour...but more interested in stop arrivals at stop by hour for HQTA
WITH trips AS (
    SELECT *
    FROM {{ ref('fct_monthly_scheduled_trips') }}
    -- table; clustered by month_first_day, name
),

trips_by_departure_hour AS (
   SELECT
      *,
        -- since trip_first_departure_sec can span beyond the 24 hour period
        -- for this aggregation, we'll be getting hours that are beyond 24
        -- edge cases might get swap dates near end of the month, but for the most part, this is fine
        CAST(TRUNC(trips.trip_first_departure_sec / 3600) AS INT) AS departure_hour_raw,
    FROM trips
),

hourly_aggregation AS (
    SELECT
        trips.month_first_day,
        trips.name,
        trips.day_type,
        -- since trip_first_departure_sec can span beyond the 24 hour period
        -- for this aggregation, we'll be getting hours that are beyond 24
        -- edge cases might get swap dates near end of the month, but for the most part, this is fine
        CASE
          WHEN departure_hour_raw >= 24 THEN departure_hour_raw - 24
          ELSE departure_hour_raw
        END AS departure_hour,

        COUNT(*) AS n_trips,
        ROUND(SUM(service_hours), 2) AS service_hours,
        COALESCE(ROUND(SUM(flex_service_hours), 2), 0) AS flex_service_hours

    FROM trips_by_departure_hour AS trips
    GROUP BY 1, 2, 3, 4
)

SELECT * FROM hourly_aggregation
