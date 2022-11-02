WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('stg_gtfs_guidelines__feed_guideline_index') }}
    WHERE check = {{ pathways_valid() }}
),

-- For this check we are only looking for errors and warnings related to pathways
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
            WHEN t2.validation_notices = 0 THEN "PASS"
            WHEN t2.validation_notices > 0 THEN "FAIL"
        END AS status
      FROM feed_guideline_index t1
      LEFT JOIN pathway_validation_notices_by_day t2
             ON t1.date = t2.date
            AND t1.feed_key = t2.feed_key
)

SELECT * FROM pathway_validation_check
