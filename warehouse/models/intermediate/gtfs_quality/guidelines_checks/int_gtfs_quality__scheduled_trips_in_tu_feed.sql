{% set min_date_array = dbt_utils.get_column_values(table=ref('fct_observed_trips'), column='dt', order_by = 'dt', max_records = 1) %}
{% set first_check_date = min_date_array[0] %}

WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ scheduled_trips_in_tu_feed() }}
),

fct_observed_trips AS (
    SELECT *
    FROM {{ ref('fct_observed_trips') }}
    WHERE tu_base64_url IS NOT NULL
),

fct_daily_scheduled_trips AS (
    SELECT * FROM {{ ref('fct_daily_scheduled_trips') }}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

compare_trips AS (
    SELECT
        quartet.service_key,
        scheduled_trips.service_date AS date,
        scheduled_trips.gtfs_dataset_key AS schedule_gtfs_dataset_key,
        scheduled_trips.feed_key AS schedule_feed_key,
        observed_trips.tu_base64_url,
        quartet.schedule_gtfs_dataset_key IS NOT NULL AS has_schedule,
        quartet.trip_updates_gtfs_dataset_key IS NOT NULL AS has_tu,
        COUNT(scheduled_trips.trip_id) AS scheduled_trips,
        COUNT(observed_trips.tu_num_distinct_message_ids) AS observed_trips,
    FROM dim_provider_gtfs_data AS quartet
    LEFT JOIN fct_daily_scheduled_trips AS scheduled_trips
        ON CAST(scheduled_trips.service_date AS TIMESTAMP) BETWEEN quartet._valid_from AND quartet._valid_to
        AND quartet.schedule_gtfs_dataset_key = scheduled_trips.gtfs_dataset_key
    LEFT JOIN fct_observed_trips AS observed_trips
      -- should this be activity date or service date?
      ON scheduled_trips.service_date = observed_trips.dt
      AND quartet.associated_schedule_gtfs_dataset_key = observed_trips.schedule_to_use_for_rt_validation_gtfs_dataset_key
      AND scheduled_trips.trip_id = observed_trips.trip_id
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),

int_gtfs_quality__scheduled_trips_in_tu_feed AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_service AND has_schedule_feed
                THEN
                    CASE
                        WHEN scheduled_trips = observed_trips THEN {{ guidelines_pass_status() }}
                        WHEN NOT has_tu THEN {{ guidelines_na_entity_status() }}
                        WHEN idx.date < '{{ first_check_date }}' THEN {{ guidelines_na_too_early_status() }}
                        WHEN scheduled_trips = 0 OR scheduled_trips IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN scheduled_trips != observed_trips THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND has_rt_feed_tu
                THEN
                    CASE
                        WHEN scheduled_trips = observed_trips THEN {{ guidelines_pass_status() }}
                        WHEN NOT has_schedule THEN {{ guidelines_na_entity_status() }}
                        WHEN idx.date < '{{ first_check_date }}' THEN {{ guidelines_na_too_early_status() }}
                        WHEN scheduled_trips = 0 OR scheduled_trips IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN scheduled_trips != observed_trips THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND NOT has_schedule_feed AND NOT has_rt_feed_tu THEN {{ guidelines_na_entity_status() }}
            ELSE idx.status
        END AS status,
    FROM guideline_index AS idx
    LEFT JOIN compare_trips
        ON idx.date = compare_trips.date
        AND idx.service_key = compare_trips.service_key
        AND (idx.schedule_feed_key = compare_trips.schedule_feed_key OR idx.base64_url = compare_trips.tu_base64_url)
)

SELECT * FROM int_gtfs_quality__scheduled_trips_in_tu_feed
