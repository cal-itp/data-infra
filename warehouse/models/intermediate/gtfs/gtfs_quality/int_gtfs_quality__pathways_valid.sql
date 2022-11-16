WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__schedule_feed_guideline_index') }}
),

unique_trip_stops AS (
    SELECT
      feed_key,
      stop_id,
      trip_id,
      COUNT(*) AS ct
    FROM {{ ref('dim_stop_times') }}
   GROUP BY 1, 2, 3
),

stops_joined AS (
    SELECT
        t1.stop_id,
        t1.trip_id,
        t1.feed_key,
        t4.stop_name,
        t4.parent_station,
        t3.route_type,
        LOWER(t4.stop_name) LIKE '%station%' OR LOWER(t4.stop_name) LIKE '%transit center%' AS keyword_match
    FROM unique_trip_stops t1
    INNER JOIN {{ ref('dim_trips') }} t2
      ON t1.trip_id = t2.trip_id
     AND t1.feed_key = t2.feed_key
    INNER JOIN {{ ref('dim_routes') }} t3
      ON t2.route_id = t3.route_id
     AND t2.feed_key = t3.feed_key
    INNER JOIN {{ ref('dim_stops') }} t4
      ON t1.stop_id = t4.stop_id
     AND t1.feed_key = t4.feed_key
),

pathways_eligibile AS (
    SELECT
        feed_key,
        COUNT(*) AS ct
    FROM stops_joined
   WHERE route_type = "2" --  Route type 2 is Rail
      OR keyword_match IS true
      OR parent_station IS NOT null
   GROUP BY 1
),

-- For this check we are only looking for errors related to pathways
validation_fact_daily_feed_codes_pathway_related AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
     WHERE code IN (
                'pathway_to_platform_with_boarding_areas',
                'pathway_to_wrong_location_type',
                'pathway_unreachable_location',
                'missing_level_id',
                'station_with_parent_station',
                'wrong_parent_location_type'
            )
),

pathway_validation_notices_by_day AS (
    SELECT
        feed_key,
        SUM(total_notices) as validation_notices
    FROM validation_fact_daily_feed_codes_pathway_related
    GROUP BY feed_key
),

int_gtfs_quality__pathways_valid AS (
    SELECT
        t1.date,
        {{ pathways_valid() }} AS check,
        {{ accurate_accessibility_data() }} AS feature,
        t1.feed_key,
        CASE
            WHEN t2.feed_key IS null THEN "N/A"
            WHEN t3.validation_notices = 0 THEN "PASS"
            WHEN t3.validation_notices > 0 THEN "FAIL"
        END AS status
      FROM feed_guideline_index t1
      LEFT JOIN pathways_eligibile t2
             ON t1.feed_key = t2.feed_key
      LEFT JOIN pathway_validation_notices_by_day t3
             ON t1.feed_key = t3.feed_key
)

SELECT * FROM int_gtfs_quality__pathways_valid
