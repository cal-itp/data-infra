{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feeds') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

-- list all the checks that have been implemented
checks_implemented AS (
    SELECT {{ static_feed_downloaded_successfully() }} AS check, {{ compliant_on_the_map() }} AS feature
    UNION ALL
    SELECT {{ no_validation_errors_in_last_30_days() }}, {{ compliant_on_the_map() }}
    UNION ALL
    SELECT {{ complete_wheelchair_accessibility_data() }}, {{ accurate_accessibility_data() }}
    UNION ALL
    SELECT {{ technical_contact_listed() }}, {{ technical_contact_availability() }}
),

-- create an index: all feed/date/check combinations
stg_gtfs_guidelines__feed_check_index AS (
    SELECT
        t2.calitp_itp_id,
        t2.calitp_url_number,
        t2.calitp_agency_name,
        t1.date,
        t1.feed_key,
        t3.check,
        t3.feature
    FROM gtfs_schedule_fact_daily_feeds AS t1
    LEFT JOIN gtfs_schedule_dim_feeds AS t2
        USING (feed_key)
    CROSS JOIN checks_implemented AS t3
)

SELECT * FROM stg_gtfs_guidelines__feed_check_index
