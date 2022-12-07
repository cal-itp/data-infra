WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index') }}
),

rt_daily_url_index AS (
    SELECT * FROM {{ ref('int_gtfs_rt__daily_url_index') }}
),

int_gtfs_quality__rt_https AS (
    SELECT
        idx.date,
        idx.base64_url,
        idx.feed_type,
        CASE WHEN idx.feed_type = 'service_alerts' THEN {{ rt_https_service_alerts() }}
             WHEN idx.feed_type = 'trip_updates' THEN {{ rt_https_trip_updates() }}
             WHEN idx.feed_type = 'vehicle_positions' THEN {{ rt_https_vehicle_positions() }}
        END AS check,
        {{ best_practices_alignment() }} AS feature,
        CASE
            WHEN string_url LIKE 'https%' THEN "PASS"
            WHEN string_url IS NOT null AND string_url NOT LIKE 'https%' THEN "FAIL"
        END AS status,
    FROM feed_guideline_index AS idx
    LEFT JOIN rt_daily_url_index AS url_index
    ON idx.date = url_index.dt
   AND idx.base64_url = url_index.base64_url
   AND idx.feed_type = url_index.type
)

SELECT * FROM int_gtfs_quality__rt_https
