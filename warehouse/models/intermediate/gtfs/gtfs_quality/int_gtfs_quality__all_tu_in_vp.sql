WITH

services_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

fct_observed_trips AS (
    SELECT * FROM {{ ref('fct_observed_trips') }}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

joined AS (
    SELECT
       idx.date,
       idx.service_key,
       COUNT(
        CASE WHEN
            f.tu_num_distinct_message_ids IS NOT NULL
            AND
            f.vp_num_distinct_message_ids IS NOT NULL
        THEN 1 END ) AS vp_and_tu_present,
       COUNT(
        CASE WHEN
            f.tu_num_distinct_message_ids IS NOT NULL
        THEN 1 END) AS tu_present
    FROM services_guideline_index AS idx

    -- Since one service can have multiple quartets, this isn't an ideal join
    -- For now we are filtering on quartet.guidelines.assessed
    -- TODO: use more specific indices
    LEFT JOIN dim_provider_gtfs_data AS quartet
    ON idx.service_key = quartet.service_key
    AND TIMESTAMP(idx.date) BETWEEN quartet._valid_from AND quartet._valid_to
    AND quartet.guidelines_assessed

    LEFT JOIN fct_observed_trips AS f
    ON idx.date = f.dt
    AND quartet.trip_updates_gtfs_dataset_key = f.tu_gtfs_dataset_key
    -- Joining on vp_gtfs_dataset_key would ensure that vp_num_distinct_message_ids was never null
    -- The below join condition may be unnecessary, though it could rule out potential cases where one TU feed is mapped to multiple schedule feeds
    AND quartet.associated_schedule_gtfs_dataset_key = f.schedule_to_use_for_rt_validation_gtfs_dataset_key
    AND f.tu_num_scheduled_canceled_added_stops > 0
    GROUP BY 1,2
),

int_gtfs_quality__all_tu_in_vp AS (
    SELECT
        service_key,
        date,
        {{ all_tu_in_vp() }} AS check,
        {{ fixed_route_completeness() }} AS feature,
        vp_and_tu_present,
        tu_present,
        CASE
            WHEN tu_present = 0 OR tu_present IS null THEN "N/A"
            WHEN vp_and_tu_present = tu_present THEN "PASS"
            ELSE "FAIL"
        END AS status,
    FROM joined
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp
