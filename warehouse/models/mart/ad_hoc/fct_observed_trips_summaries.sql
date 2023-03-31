{{ config(materialized='table') }}

WITH dim_gtfs_datasets AS (
    SELECT * FROM {{ ref('dim_gtfs_datasets') }}
),

fct_observed_trips AS (
    SELECT

        tu_gtfs_dataset_key AS gtfs_dataset_key,
        trip_id,
        dt,
        tu_num_distinct_message_ids,

        -- are these time zones correct??
        tu_min_extract_ts,
        tu_max_extract_ts,
        trip_start_time,
        vp_num_distinct_minutes_of_trip_with_vehicle_positions,

        -- Cast to interval because it's a string, with <24hr values, so cast to time breaks
        -- does this need the activity date treatment?
        CAST(trip_start_time AS INTERVAL) AS interval_trip_start_time,
        CAST(tu_min_extract_ts AS TIME) AS tu_min_extract_time

    FROM {{ ref('fct_observed_trips') }}
    WHERE dt >= '2022-12-01' AND dt < '2022-12-08'
),

select_event_time AS (

    SELECT
        fct_observed_trips.*,
        dim_gtfs_datasets.name,
        -- Weird double cast here because of the weird casting behavior in the first CTE
        COALESCE(interval_trip_start_time, CAST(CAST(tu_min_extract_time AS STRING) AS INTERVAL)) AS event_time

    FROM fct_observed_trips
    LEFT JOIN dim_gtfs_datasets
        ON (fct_observed_trips.gtfs_dataset_key = dim_gtfs_datasets.key)

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
        name,
        trip_id,
        dt,
        tu_num_distinct_message_ids,
        tu_min_extract_ts,
        tu_max_extract_ts,
        trip_start_time,
        vp_num_distinct_minutes_of_trip_with_vehicle_positions,
        time_of_day,

    FROM create_time_of_day

)

SELECT * FROM fct_observed_trips_summaries
