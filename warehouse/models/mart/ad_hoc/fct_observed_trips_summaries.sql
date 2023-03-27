{{ config(materialized='table') }}

WITH fct_observed_trips AS (
    SELECT * FROM {{ ref('fct_observed_trips') }}
),

fct_observed_trips_summaries AS (

    SELECT *

        gtfs_dataset_key,
        name,
        trip_id,
        activity_date,

        tu_num_distinct_message_ids,
        tu_min_extract_ts,
        tu_max_extract_ts,

        time_of_day

    FROM fct_observed_trips
    --GROUP BY BY 1,2,3,4

)

SELECT * FROM fct_observed_trips_summaries
