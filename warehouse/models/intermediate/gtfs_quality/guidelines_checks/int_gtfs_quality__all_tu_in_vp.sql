WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ all_tu_in_vp() }}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

-- condense large trip table to the feed/day level for more performant joins
observed_trips AS (
    SELECT
        service_date AS date,
        tu_gtfs_dataset_key,
        COUNTIF(appeared_in_tu
            AND appeared_in_vp) AS vp_and_tu_present,
        COUNTIF(appeared_in_tu
            AND NOT appeared_in_vp) AS tu_missing_vp,
    FROM {{ ref('fct_observed_trips') }}
    -- TODO: you can have a trip-level schedule relationship of scheduled, canceled, or added without having stop-level updates of those types
    -- we would need a trip level schedule_relationship on fct_observed_trips to make this more robust
    WHERE tu_num_scheduled_canceled_added_stops > 0
    GROUP BY 1, 2
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM observed_trips
),

-- take the individual VP/TU comparison and roll them up to the service level
map_trips_to_services AS (
    SELECT
        idx.date,
        idx.service_key,
        idx.gtfs_dataset_key,
        LOGICAL_OR(quartet.vehicle_positions_gtfs_dataset_key IS NOT NULL) AS quartet_has_vp,
        LOGICAL_OR(quartet.trip_updates_gtfs_dataset_key IS NOT NULL) AS quartet_has_tu,
        SUM(observed_trips.vp_and_tu_present) AS vp_and_tu_present,
        SUM(observed_trips.tu_missing_vp) AS tu_missing_vp,
    FROM guideline_index AS idx
    LEFT JOIN dim_provider_gtfs_data AS quartet
        ON CAST(idx.date AS TIMESTAMP) BETWEEN quartet._valid_from AND quartet._valid_to
        AND quartet.service_key = idx.service_key
        AND (idx.gtfs_dataset_key = quartet.schedule_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.trip_updates_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.vehicle_positions_gtfs_dataset_key
            OR idx.gtfs_dataset_key = quartet.service_alerts_gtfs_dataset_key)
    LEFT JOIN observed_trips
        ON idx.date = observed_trips.date
        AND quartet.trip_updates_gtfs_dataset_key = observed_trips.tu_gtfs_dataset_key
    WHERE idx.service_key IS NOT NULL
    GROUP BY 1, 2, 3
),

int_gtfs_quality__all_tu_in_vp AS (
    SELECT
        idx.* EXCEPT(status),
        map_trips_to_services.quartet_has_tu,
        map_trips_to_services.quartet_has_vp,
        map_trips_to_services.tu_missing_vp,
        map_trips_to_services.vp_and_tu_present,
        first_check_date,
        CASE
            -- we only want to assign a substantive status on rows that have both a TU and a VP feed
            WHEN has_service AND has_rt_feed_tu
                THEN
                    CASE
                        WHEN tu_missing_vp = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        -- if we don't have a vehicle positions feed, say we don't have all the necessary entities
                        WHEN NOT quartet_has_vp THEN {{ guidelines_na_entity_status() }}
                        WHEN tu_missing_vp IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN tu_missing_vp > 0 THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND has_rt_feed_vp
                THEN
                    CASE
                        WHEN tu_missing_vp = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        -- if we don't have a trip updates feed, say we don't have all the necessary entities
                        WHEN NOT quartet_has_tu THEN {{ guidelines_na_entity_status() }}
                        WHEN tu_missing_vp IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN tu_missing_vp > 0 THEN {{ guidelines_fail_status() }}
                    END
            WHEN has_service AND NOT has_rt_feed_tu AND NOT has_rt_feed_vp THEN {{ guidelines_na_entity_status() }}
            ELSE idx.status
        END AS status,
    FROM guideline_index AS idx
    CROSS JOIN check_start
    LEFT JOIN map_trips_to_services
        ON idx.date = map_trips_to_services.date
        AND idx.service_key = map_trips_to_services.service_key
        AND idx.gtfs_dataset_key = map_trips_to_services.gtfs_dataset_key
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp
