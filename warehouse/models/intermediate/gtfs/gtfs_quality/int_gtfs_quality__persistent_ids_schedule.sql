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

stop_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("stop_id","dim_stops") }}
),

route_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("route_id","dim_routes") }}
),

agency_id_comparison AS (
    SELECT * FROM {{ ids_version_compare_aggregate("agency_id","dim_agency") }}
),

stop_id_aggregate AS (

    SELECT base64_url,
            feed_key,
            -- Total id's in current and previous feeds
            COUNT(CASE WHEN id IS NOT null AND prev_id IS NOT null THEN 1 END) AS ids_both_feeds,
            -- Total id's in current feed
            COUNT(CASE WHEN id IS NOT null THEN 1 END) AS ids_current_feed,
            -- Total id's in current feed
            COUNT(CASE WHEN prev_id IS NOT null THEN 1 END) AS ids_prev_feed,
            -- New id's added
            COUNT(CASE WHEN prev_id IS null THEN 1 END) AS id_added,
            -- Previous id's removed
            COUNT(CASE WHEN id IS null THEN 1 END) AS id_removed
        FROM stop_id_comparison
        GROUP BY 1, 2
    HAVING ids_current_feed > 0

),

route_id_aggregate AS (

    SELECT base64_url,
            feed_key,
            -- Total id's in current and previous feeds
            COUNT(CASE WHEN id IS NOT null AND prev_id IS NOT null THEN 1 END) AS ids_both_feeds,
            -- Total id's in current feed
            COUNT(CASE WHEN id IS NOT null THEN 1 END) AS ids_current_feed,
            -- Total id's in current feed
            COUNT(CASE WHEN prev_id IS NOT null THEN 1 END) AS ids_prev_feed,
            -- New id's added
            COUNT(CASE WHEN prev_id IS null THEN 1 END) AS id_added,
            -- Previous id's removed
            COUNT(CASE WHEN id IS null THEN 1 END) AS id_removed
        FROM route_id_comparison
        GROUP BY 1, 2
    HAVING ids_current_feed > 0

),

agency_id_aggregate AS (

    SELECT base64_url,
            feed_key,
            -- Total id's in current and previous feeds
            COUNT(CASE WHEN id IS NOT null AND prev_id IS NOT null THEN 1 END) AS ids_both_feeds,
            -- Total id's in current feed
            COUNT(CASE WHEN id IS NOT null THEN 1 END) AS ids_current_feed,
            -- Total id's in current feed
            COUNT(CASE WHEN prev_id IS NOT null THEN 1 END) AS ids_prev_feed,
            -- New id's added
            COUNT(CASE WHEN prev_id IS null THEN 1 END) AS id_added,
            -- Previous id's removed
            COUNT(CASE WHEN id IS null THEN 1 END) AS id_removed
        FROM agency_id_comparison
        GROUP BY 1, 2
    HAVING ids_current_feed > 0

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
      LEFT JOIN stop_id_aggregate AS t2
        ON t2.feed_key = t1.feed_key
      LEFT JOIN route_id_aggregate AS t3
        ON t3.feed_key = t1.feed_key
      LEFT JOIN agency_id_aggregate AS t4
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
