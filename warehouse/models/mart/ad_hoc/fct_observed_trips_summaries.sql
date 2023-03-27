{{ config(materialized='table') }}

WITH fct_observed_trips AS (
    SELECT * FROM {{ ref('fct_observed_trips') }}
),

select_time_of_day AS (

    SELECT

        fct_observed_trips.*,
        CASE
            WHEN schedule.trip_id IS NOT NULL AND rt.trip_id IS NOT NULL THEN schedule.trip_id
            ELSE tu_min_extract_ts
        END
        AS time_of_day

    FROM fct_daily_scheduled_trips
    fct_observed_trips

),

label_day_part AS (

        CASE
            WHEN EXTRACT(hour FROM time_of_day) < 4 THEN "OWL"
            WHEN EXTRACT(hour FROM time_of_day) < 7 THEN "Early AM"
            WHEN EXTRACT(hour FROM time_of_day) < 10 THEN "AM Peak"
            WHEN EXTRACT(hour FROM time_of_day) < 15 THEN "Midday"
            WHEN EXTRACT(hour FROM time_of_day) < 20 THEN "PM Peak"
            ELSE "Evening"
        END
        AS day_part,

)

fct_observed_trips_summaries AS (

    SELECT

        gtfs_dataset_key,
        name,
        trip_id,
        activity_date,

        tu_num_distinct_message_ids,
        tu_min_extract_ts,
        tu_max_extract_ts,

    FROM fct_observed_trips
    --GROUP BY BY 1,2,3,4

)

SELECT * FROM fct_observed_trips_summaries
