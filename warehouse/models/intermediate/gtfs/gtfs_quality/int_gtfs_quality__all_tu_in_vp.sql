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
    LEFT JOIN dim_provider_gtfs_data AS quartet
    ON idx.service_key = quartet.service_key
    AND idx.date BETWEEN EXTRACT(DATE FROM quartet._valid_from) AND EXTRACT(DATE FROM quartet._valid_to)
    LEFT JOIN fct_observed_trips AS f
    ON quartet.associated_schedule_gtfs_dataset_key = f.schedule_to_use_for_rt_validation_gtfs_dataset_key
    AND idx.date = f.dt
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
        CASE WHEN
            vp_and_tu_present * 1.0 / NULLIF(tu_present,0) = 1 THEN "PASS"
            ELSE "FAIL"
        END AS status,
    FROM joined
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp