WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ pathways_valid() }}
),

unique_trip_stops AS (
    SELECT
      calitp_itp_id,
      calitp_url_number,
      calitp_extracted_at,
      calitp_deleted_at,
      stop_id,
      trip_id,
      COUNT(*) AS ct
    FROM {{ ref('gtfs_schedule_dim_stop_times') }}
   GROUP BY 1,2,3,4,5,6
),

stops_joined AS (
    SELECT
        t1.stop_id,
        t1.trip_id,
        t1.calitp_extracted_at,
        t1.calitp_deleted_at,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t4.stop_name,
        t4.parent_station,
        t3.route_type,
        t4.stop_name,
        CASE
            WHEN LOWER(t4.stop_name) LIKE '%station%' OR LOWER(t4.stop_name) LIKE '%transit center%' THEN true
        ELSE false
        END AS keyword_match
    FROM unique_trip_stops t1
    LEFT JOIN {{ ref('trips_clean') }} t2
      ON t1.trip_id = t2.trip_id
     AND t1.calitp_extracted_at = t2.calitp_extracted_at
     AND t1.calitp_deleted_at = t2.calitp_deleted_at
    JOIN {{ ref('gtfs_schedule_dim_routes') }} t3
      ON t2.route_id = t3.route_id
     AND t2.calitp_extracted_at = t3.calitp_extracted_at
     AND t2.calitp_deleted_at = t3.calitp_deleted_at
    JOIN {{ ref('stops_clean') }} t4
      ON t1.stop_id = t4.stop_id
     AND t1.calitp_extracted_at = t4.calitp_extracted_at
     AND t1.calitp_deleted_at = t4.calitp_deleted_at
),

pathways_eligibile AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        calitp_extracted_at,
        calitp_deleted_at,
        COUNT(*) AS ct
    FROM stops_joined
   WHERE route_type = "2" --  Route type 2 is Rail
      OR keyword_match IS true
      OR parent_station IS NOT null
   GROUP BY 1,2,3,4
),

-- For this check we are only looking for notices related to pathways
validation_fact_daily_feed_codes_pathway_related AS (
    SELECT * FROM {{ ref('validation_fact_daily_feed_codes') }}
     WHERE code IN (
                    'pathway_to_platform_with_boarding_areas',
                    'pathway_to_wrong_location_type',
                    'pathway_unreachable_location',
                    'pathway_dangling_generic_node',
                    'pathway_loop',
                    'missing_level_id',
                    'platform_without_parent_station',
                    'station_with_parent_station',
                    'wrong_parent_location_type'
            )
),

pathway_validation_notices_by_day AS (
    SELECT
        feed_key,
        date,
        SUM(n_notices) as validation_notices
    FROM validation_fact_daily_feed_codes_pathway_related
    GROUP BY feed_key, date
),

pathway_validation_check AS (
    SELECT
        t1.date,
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.calitp_agency_name,
        t1.feed_key,
        t1.check,
        t1.feature,
        CASE
            WHEN t2.calitp_itp_id IS null THEN "N/A"
            WHEN t3.validation_notices = 0 THEN "PASS"
            WHEN t3.validation_notices > 0 THEN "FAIL"
        END AS status,
        -- Count for deduping - the alternative is to perform some row-level deduping in the pathways_eligibile subquery
        COUNT(*) AS ct
      FROM feed_guideline_index t1
      LEFT JOIN pathways_eligibile t2
             ON t1.date >= t2.calitp_extracted_at
            AND t1.date < t2.calitp_deleted_at
            AND t1.calitp_itp_id = t2.calitp_itp_id
            and t1.calitp_url_number = t2.calitp_url_number
      LEFT JOIN pathway_validation_notices_by_day t3
             ON t1.date = t3.date
            AND t1.feed_key = t3.feed_key
     GROUP BY 1,2,3,4,5,6,7,8
),

pathway_validation_check_final AS (
    SELECT
        date,
        calitp_itp_id,
        calitp_url_number,
        calitp_agency_name,
        feed_key,
        check,
        feature,
        status
      FROM pathway_validation_check
)

SELECT * FROM pathway_validation_check_final
