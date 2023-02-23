WITH feed_guideline_index AS (
    SELECT * FROM {{ ref('int_gtfs_quality__rt_feed_guideline_index_aggregator') }}
),

scraped_urls AS (
    SELECT *
    FROM {{ ref('stg_gtfs_quality__scraped_urls') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

daily_scraped_urls AS (
    SELECT DISTINCT dt AS date,
           aggregator,
           feed_url_str
      FROM scraped_urls
),

int_gtfs_quality__feed_aggregator_rt AS (
    SELECT
        t1.date,
        t1.base64_url,
        t1.feed_type,
        t1.aggregator,
        CASE
            WHEN t1.aggregator = 'transitland' THEN
                CASE
                    WHEN t1.feed_type = "vehicle_positions" THEN {{ vehicle_positions_feed_on_transitland() }}
                    WHEN t1.feed_type = "trip_updates" THEN {{ trip_updates_feed_on_transitland() }}
                    WHEN t1.feed_type = "service_alerts" THEN {{ service_alerts_feed_on_transitland() }}
                END
            WHEN t1.aggregator = 'mobility_database' THEN
                CASE
                    WHEN t1.feed_type = "vehicle_positions" THEN {{ vehicle_positions_feed_on_mobility_database() }}
                    WHEN t1.feed_type = "trip_updates" THEN {{ trip_updates_feed_on_mobility_database() }}
                    WHEN t1.feed_type = "service_alerts" THEN {{ service_alerts_feed_on_mobility_database() }}
                END
        END AS check,
        {{ feed_aggregator_availability_rt() }} AS feature,
        CASE
            WHEN t3.aggregator IS NOT null THEN "PASS"
            ELSE "FAIL"
        END AS status,
      FROM feed_guideline_index t1
      LEFT JOIN dim_gtfs_datasets t2
        ON t2.base64_url = t1.base64_url
        AND CAST(t1.date AS TIMESTAMP) BETWEEN t2._valid_from AND t2._valid_to
      LEFT JOIN daily_scraped_urls AS t3
        ON {{ url_remove_scheme('t3.feed_url_str') }} = {{ url_remove_scheme('t2.uri') }}
       AND t3.date = t1.date
       AND t3.aggregator = t1.aggregator
)

SELECT * FROM int_gtfs_quality__feed_aggregator_rt
