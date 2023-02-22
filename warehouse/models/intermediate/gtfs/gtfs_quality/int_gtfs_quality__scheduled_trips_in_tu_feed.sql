WITH

services_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

fct_observed_trips AS (
    SELECT * FROM {{ ref('fct_observed_trips') }}
),

fct_daily_scheduled_trips AS (
    SELECT * FROM {{ ref('fct_daily_scheduled_trips') }}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

joined AS (
    SELECT
       idx.date,
       idx.service_key,
       LOGICAL_OR(quartet.key IS NOT null) AS has_tu_feed,
       COUNT(scheduled_trips.trip_id) AS scheduled_trips,
       COUNT(observed_trips.tu_num_distinct_message_ids) AS observed_trips,
    FROM services_guideline_index AS idx

    -- Since one service can have multiple quartets, this isn't an ideal join
    -- For now we are filtering on quartet.guidelines.assessed
    -- TODO: use more specific indices
    LEFT JOIN dim_provider_gtfs_data AS quartet
    ON idx.service_key = quartet.service_key
    AND TIMESTAMP(idx.date) BETWEEN quartet._valid_from AND quartet._valid_to
    AND quartet.guidelines_assessed
    -- We're only interested in provider_gtfs_data rows that have both an associated_schedule_gtfs_dataset_key and a trip_updates_gtfs_dataset_key
    AND quartet.trip_updates_gtfs_dataset_key IS NOT null

    LEFT JOIN fct_daily_scheduled_trips AS scheduled_trips
      ON idx.date = scheduled_trips.service_date
     AND quartet.associated_schedule_gtfs_dataset_key = scheduled_trips.gtfs_dataset_key

    LEFT JOIN fct_observed_trips AS observed_trips
      ON idx.date = observed_trips.dt
     AND quartet.associated_schedule_gtfs_dataset_key = observed_trips.schedule_to_use_for_rt_validation_gtfs_dataset_key
     AND scheduled_trips.trip_id = observed_trips.trip_id

     GROUP BY 1,2
),

int_gtfs_quality__scheduled_trips_in_tu_feed AS (
    SELECT
        service_key,
        date,
        {{ scheduled_trips_in_tu_feed() }} AS check,
        {{ fixed_route_completeness() }} AS feature,
        scheduled_trips,
        observed_trips,
        CASE
            WHEN
                NOT(has_tu_feed)
                OR scheduled_trips = 0 OR
                scheduled_trips IS null
                THEN "N/A"
            WHEN scheduled_trips = observed_trips THEN "PASS"
            ELSE "FAIL"
        END AS status,
    FROM joined
)

SELECT * FROM int_gtfs_quality__scheduled_trips_in_tu_feed
