{{ config(materialized='table') }}

WITH fct_observed_trips AS (
    SELECT

        tu_gtfs_dataset_key AS gtfs_dataset_key,
        --name,
        trip_id,
        dt,
        tu_num_distinct_message_ids,

        -- do all of these need to be converted from UTC ??
        tu_min_extract_ts,
        tu_max_extract_ts,
        trip_start_time,

        -- Cast to interval because it's a string, with <24hr values, so cast to time breaks
        CAST(trip_start_time AS INTERVAL) AS interval_trip_start_time,
        CAST(tu_min_extract_ts AS TIME) AS tu_min_extract_time

    FROM {{ ref('fct_observed_trips') }}
    WHERE dt >= '2022-12-01' AND dt < '2022-12-08'
),

select_event_time AS (

    SELECT
        *,
        -- Weird double cast here because of the weird casting behavior in the first CTE
        COALESCE(interval_trip_start_time, CAST(CAST(tu_min_extract_time AS STRING) AS INTERVAL)) AS event_time

    FROM fct_observed_trips

),

create_time_of_day AS (

    SELECT

        *,
        CASE
            WHEN EXTRACT(hour FROM event_time) < 4 THEN "OWL"
            WHEN EXTRACT(hour FROM event_time) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM event_time) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM event_time) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM event_time) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS time_of_day,

    FROM select_event_time

),

fct_observed_trips_summaries AS (

    SELECT

        gtfs_dataset_key,
        --name,
        trip_id,
        dt,
        tu_num_distinct_message_ids,
        tu_min_extract_ts,
        tu_max_extract_ts,
        trip_start_time,
        time_of_day,

        -- need more clarity from Tiffany on how to deduce the column below
        --number_of_distinct_minutes_with_vp,

    FROM create_time_of_day

)

SELECT * FROM fct_observed_trips_summaries
