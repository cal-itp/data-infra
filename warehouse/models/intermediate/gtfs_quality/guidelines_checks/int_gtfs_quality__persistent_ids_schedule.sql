WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
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

-- SQLFluff thinks this CTE isn't used, but it is required for the ids_version_compare_aggregate macro
feed_version_history AS ( -- noqa: disable=L045
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

-- noqa: enable=L045
stop_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("stop_id", "dim_stops") }}
),

route_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("route_id", "dim_routes") }}
),

agency_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("agency_id", "dim_agency") }}
),

id_change_count AS (
    SELECT t1.date,
           t1.feed_key,
           MAX(t2.id_added * 100 / t2.ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                    )
                AS max_percent_stop_ids_new,
           MAX(t3.id_added * 100 / t3.ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                    )
                AS max_percent_route_ids_new,
           MAX(t4.id_added * 100 / t4.ids_current_feed )
               OVER (
                   PARTITION BY t1.feed_key
                   ORDER BY t1.date
                   ROWS BETWEEN 30 PRECEDING AND CURRENT ROW
                    )
                AS max_percent_agency_ids_new
      FROM feed_guideline_index AS t1
      LEFT JOIN stop_id_comparison AS t2
        ON t2.feed_key = t1.feed_key
      LEFT JOIN route_id_comparison AS t3
        ON t3.feed_key = t1.feed_key
      LEFT JOIN agency_id_comparison AS t4
        ON t4.feed_key = t1.feed_key
),

int_gtfs_quality__persistent_ids_schedule AS (
    SELECT date,
           feed_key,
           {{ persistent_ids_schedule() }} AS check,
           {{ best_practices_alignment_schedule() }} AS feature,
           CASE WHEN max_percent_stop_ids_new > 50
                     OR max_percent_route_ids_new > 50
                     OR max_percent_agency_ids_new > 50
                THEN {{ guidelines_fail_status() }}
                ELSE {{ guidelines_pass_status() }}
           END AS status
      FROM id_change_count
)

SELECT * FROM int_gtfs_quality__persistent_ids_schedule
