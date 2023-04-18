WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ persistent_ids_schedule() }}
),

dim_stops AS (
    SELECT  * FROM {{ ref('dim_stops') }}
),

dim_routes AS (
    SELECT  * FROM {{ ref('dim_routes') }}
),

dim_agency AS (
    SELECT  * FROM {{ ref('dim_agency') }}
),

feed_version_history AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

stop_id_comparison AS (
    SELECT base64_url, feed_key, id_added * 100 / ids_current_feed AS pct_added
    FROM {{ ids_version_compare_aggregate("stop_id", "dim_stops") }}
),

route_id_comparison AS (
    SELECT base64_url, feed_key, id_added * 100 / ids_current_feed AS pct_added
    FROM {{ ids_version_compare_aggregate("route_id", "dim_routes") }}
),

agency_id_comparison AS (
    SELECT base64_url, feed_key, id_added * 100 / ids_current_feed AS pct_added
    FROM {{ ids_version_compare_aggregate("agency_id", "dim_agency") }}
),

id_change_count AS (
    SELECT hist.feed_key,
        stops.pct_added AS stops_pct_added,
        routes.pct_added AS routes_pct_added,
        agency.pct_added AS agency_pct_added,
        GREATEST(stops.pct_added, routes.pct_added, agency.pct_added) AS max_change_pct,
        hist.valid_from,
        DATE_ADD(valid_from, INTERVAL 30 DAY) AS int_30_days
      FROM feed_version_history AS hist
      LEFT JOIN stop_id_comparison AS stops
        ON hist.feed_key = stops.feed_key
      LEFT JOIN route_id_comparison AS routes
        ON hist.feed_key = routes.feed_key
      LEFT JOIN agency_id_comparison AS agency
        ON hist.feed_key = agency.feed_key
),

check_start AS (
    SELECT MIN(valid_from) AS first_check_date
    FROM feed_version_history
    WHERE prev_feed_key IS NOT NULL
),

int_gtfs_quality__persistent_ids_schedule AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        stops_pct_added,
        routes_pct_added,
        agency_pct_added,
        max_change_pct,
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN max_change_pct <= 50 OR idx.date > int_30_days THEN {{ guidelines_pass_status() }}
                        WHEN (stops_pct_added > 50 OR routes_pct_added > 50 OR agency_pct_added > 50) AND idx.date <= int_30_days THEN {{ guidelines_fail_status() }}
                        -- order matters -- this has to come after the fail line in case any are missing but another is > 50
                        WHEN max_change_pct IS NULL THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN id_change_count
        ON idx.schedule_feed_key = id_change_count.feed_key
)

SELECT * FROM int_gtfs_quality__persistent_ids_schedule
