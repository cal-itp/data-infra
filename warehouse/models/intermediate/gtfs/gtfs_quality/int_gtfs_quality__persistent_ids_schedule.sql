
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

feed_version_history AS (
    SELECT * FROM {{ ref('int_gtfs_quality__feed_version_history') }}
),

stop_id_comparison AS ( {{ ids_version_compare_aggregate("stop_id","dim_stops") }} ),
route_id_comparison AS ( {{ ids_version_compare_aggregate("route_id","dim_routes") }} ),
agency_id_comparison AS ( {{ ids_version_compare_aggregate("agency_id","dim_agency") }} ),

id_change_count AS (
    SELECT t1.date,
           t1.feed_key,
           {{ max_new_id_ratio("t2") }} AS max_percent_stop_ids_new,
           {{ max_new_id_ratio("t3") }} AS max_percent_route_ids_new,
           {{ max_new_id_ratio("t4") }} AS max_percent_agency_ids_new
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
                THEN "FAIL"
                ELSE "PASS"
           END AS status
      FROM id_change_count
)

SELECT * FROM int_gtfs_quality__persistent_ids_schedule
