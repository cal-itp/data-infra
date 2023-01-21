WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_services') }}
),

daily_trip_update_trips AS (
    SELECT DISTINCT
          dt AS date,
          base64_url,
          trip_id,
          trip_schedule_relationship
    FROM {{ ref('int_gtfs_rt__trip_updates_summaries') }}
),

daily_vehicle_position_trips AS (
    SELECT DISTINCT
          dt AS date,
          base64_url,
          trip_id
    FROM {{ ref('fct_vehicle_positions_messages') }}
),

joined AS (
    SELECT s.service_id,
           s.date,
           tu.trip_id AS tu_trip_id,
           vp.trip_id AS vp_trip_id
      FROM feed_guideline_index s
      JOIN daily_trip_update_trips tu
        ON tu.date = s.date
       AND tu.base64_url = s.tu_base_64_url
      LEFT JOIN daily_vehicle_position_trips vp
        ON vp.date = s.date
       AND vp.base64_url = s.vp_base_64_url
),

int_gtfs_quality__all_tu_in_vp AS (
    SELECT service_id,
           date,
           {{ all_tu_in_vp() }} AS check,
           {{ fixed_route_completeness() }} AS feature,
            CASE WHEN COUNT(CASE WHEN vp_trip_id IS NOT null THEN 1 END) * 1.0 / COUNT(*) = 1 THEN "PASS"
                 ELSE "FAIL"
            END AS status,
      FROM joined
     GROUP BY 1,2
)

SELECT * FROM int_gtfs_quality__all_tu_in_vp