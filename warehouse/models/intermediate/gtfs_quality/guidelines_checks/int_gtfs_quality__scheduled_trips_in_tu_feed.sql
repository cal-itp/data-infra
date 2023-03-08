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

-- simply compare scheduled vs. observed RT trips
-- condense these large trip tables to the feed/day level for more performant joins
compare_trips AS (
    SELECT
        scheduled_trips.service_date AS date,
        scheduled_trips.gtfs_dataset_key AS schedule_gtfs_dataset_key,
        scheduled_trips.feed_key AS schedule_feed_key,
<<<<<<< HEAD
        COUNT(DISTINCT scheduled_trips.trip_id) AS scheduled_trips,
        COUNT(DISTINCT observed_trips.trip_id) AS observed_trips,
=======
        observed_trips.tu_gtfs_dataset_key,
        observed_trips.tu_base64_url,
        COUNT(DISTINCT scheduled_trips.trip_id) AS scheduled_trips,
        COUNTIF(observed_trips.trip_id IS NOT NULL) AS observed_trips,
>>>>>>> 9300de57 (Migrate first batch of guideline checks to use new indices (#2340))
    FROM fct_daily_scheduled_trips AS scheduled_trips
    LEFT JOIN fct_observed_trips AS observed_trips
      -- should this be activity date or service date? will depend on fix for https://github.com/cal-itp/data-infra/issues/2347
      ON scheduled_trips.service_date = observed_trips.dt
      AND scheduled_trips.gtfs_dataset_key = observed_trips.schedule_to_use_for_rt_validation_gtfs_dataset_key
      AND scheduled_trips.trip_id = observed_trips.trip_id
<<<<<<< HEAD
    GROUP BY 1, 2, 3
=======
    GROUP BY 1, 2, 3, 4, 5
>>>>>>> 9300de57 (Migrate first batch of guideline checks to use new indices (#2340))
),

check_start AS (
    SELECT MIN(dt) AS first_check_date
    FROM fct_observed_trips
),

<<<<<<< HEAD
-- take the individual schedule/TU comparison and roll them up to the service level
=======
-- take the individual schedule/TU feed comparisons and roll them up to the service level
>>>>>>> 9300de57 (Migrate first batch of guideline checks to use new indices (#2340))
map_trips_to_services AS (
    SELECT
        idx.date,
        idx.service_key,
        idx.gtfs_dataset_key,
        LOGICAL_OR(quartet.schedule_gtfs_dataset_key IS NOT NULL) AS quartet_has_schedule,
        LOGICAL_OR(quartet.trip_updates_gtfs_dataset_key IS NOT NULL) AS quartet_has_tu,
        SUM(compare_trips.observed_trips) AS observed_trips,
        SUM(compare_trips.scheduled_trips) AS scheduled_trips,
    FROM guideline_index AS idx
    LEFT JOIN dim_provider_gtfs_data AS quartet
        ON CAST(idx.date AS TIMESTAMP) BETWEEN quartet._valid_from AND quartet._valid_to
        AND quartet.service_key = idx.service_key
        AND (idx.gtfs_dataset_key = quartet.schedule_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.trip_updates_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.vehicle_positions_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.service_alerts_gtfs_dataset_key)
    LEFT JOIN compare_trips
        ON idx.date = compare_trips.date
        AND quartet.schedule_gtfs_dataset_key = compare_trips.schedule_gtfs_dataset_key
<<<<<<< HEAD
=======
        AND quartet.trip_updates_gtfs_dataset_key = compare_trips.tu_gtfs_dataset_key
>>>>>>> 9300de57 (Migrate first batch of guideline checks to use new indices (#2340))
    WHERE idx.service_key IS NOT NULL
    GROUP BY 1, 2, 3
),

int_gtfs_quality__scheduled_trips_in_tu_feed AS (
    SELECT
        idx.* EXCEPT(status),
        map_trips_to_services.quartet_has_tu,
        map_trips_to_services.quartet_has_schedule,
        map_trips_to_services.observed_trips,
        map_trips_to_services.scheduled_trips,
        first_check_date,
        CASE
            -- we only want to assign a substantive status on rows that have both a service and either a schedule or a TU feed
            WHEN has_service AND has_schedule_feed
                THEN
                    CASE
                        WHEN scheduled_trips = observed_trips THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        -- if we don't have a trip updates feed, say we don't have all the necessary entities
                        WHEN NOT quartet_has_tu THEN {{ guidelines_na_entity_status() }}
                        WHEN scheduled_trips IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN scheduled_trips != observed_trips THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND has_rt_feed_tu
                THEN
                    CASE
                        WHEN scheduled_trips = observed_trips THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        -- if we don't have a schedule feed, say we don't have all the necessary entities
                        WHEN NOT quartet_has_schedule THEN {{ guidelines_na_entity_status() }}
                        WHEN scheduled_trips IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN scheduled_trips != observed_trips THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND NOT has_schedule_feed AND NOT has_rt_feed_tu THEN {{ guidelines_na_entity_status() }}
            ELSE idx.status
        END AS status,
    FROM guideline_index AS idx
    CROSS JOIN check_start
    LEFT JOIN map_trips_to_services
        ON idx.date = map_trips_to_services.date
        AND idx.service_key = map_trips_to_services.service_key
        AND idx.gtfs_dataset_key = map_trips_to_services.gtfs_dataset_key
)

SELECT * FROM int_gtfs_quality__scheduled_trips_in_tu_feed
