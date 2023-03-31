WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ pathways_valid() }}
),

dim_stops AS (
    SELECT * FROM {{ ref('dim_stops') }}
),

dim_routes AS (
    SELECT * FROM {{ ref('dim_routes') }}
),

files AS (
    SELECT * FROM {{ ref('fct_schedule_feed_files') }}
),

-- For this check we are only looking for errors related to pathways
pathways_notices AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
    WHERE code IN (
                'pathway_to_platform_with_boarding_areas',
                'pathway_to_wrong_location_type',
                'pathway_unreachable_location',
                'missing_level_id',
                'station_with_parent_station',
                'wrong_parent_location_type'
            )
),

feed_has_rail AS (
    SELECT
        feed_key,
        -- see: https://gtfs.org/schedule/reference/#routestxt for route type definitions
        LOGICAL_OR(route_type = "2") AS has_rail
    FROM dim_routes
    GROUP BY 1
),

feed_has_stations AS (
    SELECT
        feed_key,
        LOGICAL_OR(parent_station IS NOT NULL) AS has_parent_station,
        -- keywords associated with stops of interest were identified through discussion with team
        -- may be iterated on in future
        LOGICAL_OR(LOWER(stop_name) LIKE '%station%' OR LOWER(stop_name) LIKE '%transit center%') AS has_station_name
    FROM dim_stops
    GROUP BY 1
),

feed_has_pathways AS (
    SELECT
        feed_key,
        LOGICAL_OR(gtfs_filename = "pathways") AS has_pathways
    FROM files
    GROUP BY 1
),

pathways_eligibile AS (
    SELECT
        COALESCE(rail.feed_key, stations.feed_key) AS feed_key,
        COALESCE(has_parent_station, FALSE)
            OR COALESCE(has_station_name, FALSE)
            OR COALESCE(has_rail, FALSE)
            AS is_pathways_eligible,
        has_parent_station,
        has_rail,
        has_station_name
    FROM feed_has_rail AS rail
    FULL OUTER JOIN feed_has_stations AS stations
        ON rail.feed_key = stations.feed_key
),

feed_pathways_notices AS (
    SELECT
        feed_key,
        SUM(total_notices) AS validation_notices
    FROM pathways_notices
    GROUP BY 1
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM pathways_notices
),

int_gtfs_quality__pathways_valid AS (
    SELECT
        idx.* EXCEPT(status),

        is_pathways_eligible,
        has_parent_station,
        has_rail,
        has_pathways,
        has_station_name,
        validation_notices,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN is_pathways_eligible AND has_pathways AND validation_notices = 0 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN NOT COALESCE(is_pathways_eligible, FALSE) OR (feed_pathways_notices.feed_key IS NULL) THEN {{ guidelines_na_check_status() }}
                        WHEN is_pathways_eligible AND (validation_notices > 0 OR NOT has_pathways) THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_has_pathways
        ON idx.schedule_feed_key = feed_has_pathways.feed_key
    LEFT JOIN feed_pathways_notices
        ON idx.schedule_feed_key = feed_pathways_notices.feed_key
    LEFT JOIN pathways_eligibile
        ON idx.schedule_feed_key = pathways_eligibile.feed_key
)

SELECT * FROM int_gtfs_quality__pathways_valid
