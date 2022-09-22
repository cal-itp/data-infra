{{ config(materialized='table') }}

WITH gtfs_schedule_fact_daily_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_fact_daily_feeds') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT * FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

-- list all the checks that have been implemented
checks_implemented AS (
    SELECT {{ static_feed_downloaded_successfully() }} AS check, {{ compliance() }} AS feature
    UNION ALL
    SELECT {{ no_validation_errors() }}, {{ compliance() }}
    UNION ALL
    SELECT {{ complete_wheelchair_accessibility_data() }}, {{ accurate_accessibility_data() }}
    UNION ALL
    SELECT {{ shapes_file_present() }}, {{ accurate_service_data() }}
    UNION ALL
    SELECT {{ shapes_valid() }}, {{ accurate_service_data() }}
    UNION ALL
    SELECT {{ pathways_valid() }}, {{ accurate_accessibility_data() }}
    UNION ALL
    SELECT {{ technical_contact_listed() }}, {{ technical_contact_availability() }}
    UNION ALL
    SELECT {{ no_rt_critical_validation_errors() }}, {{ compliance() }}
    UNION ALL
    SELECT {{ trip_id_alignment() }}, {{ fixed_route_completeness() }}
    UNION ALL
    SELECT {{ vehicle_positions_feed_present() }}, {{ compliance() }}
    UNION ALL
    SELECT {{ trip_updates_feed_present() }}, {{ compliance() }}
    UNION ALL
    SELECT {{ service_alerts_feed_present() }}, {{ compliance() }}
    UNION ALL
    SELECT {{ schedule_feed_on_transitland() }}, {{ feed_aggregator_availability() }}
    UNION ALL
    SELECT {{ vehicle_positions_feed_on_transitland() }}, {{ feed_aggregator_availability() }}
    UNION ALL
    SELECT {{ trip_updates_feed_on_transitland() }}, {{ feed_aggregator_availability() }}
    UNION ALL
    SELECT {{ service_alerts_feed_on_transitland() }}, {{ feed_aggregator_availability() }}
),

-- create an index: all feed/date/check combinations
-- we never want results from the current date, as data will be incomplete
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
    WHERE t1.date < CURRENT_DATE
)

SELECT * FROM stg_gtfs_guidelines__feed_check_index
