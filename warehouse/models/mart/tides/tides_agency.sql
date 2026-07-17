{{
    config(
        materialized='table',
        tags=['tides_reference'],
    )
}}

-- GTFS agency reference for the published TIDES dataset from the schedule feeds of organizations

WITH member_feed_urls AS (
    SELECT DISTINCT base64_url
    FROM {{ ref('tides_gtfs_datasets') }}
),

member_schedule_feeds AS (
    SELECT
        key,
        _valid_from,
        _valid_to,
        _is_current
    FROM {{ ref('dim_schedule_feeds') }}
    WHERE base64_url IN (SELECT base64_url FROM member_feed_urls)
),

tides_agency AS (
    SELECT
        agency.key,
        agency.feed_key,
        agency.base64_url,
        agency.agency_id,
        agency.agency_name,
        agency.agency_url,
        agency.agency_timezone,
        agency.agency_lang,
        agency.agency_phone,
        agency.agency_fare_url,
        agency.agency_email,
        feeds._valid_from,
        feeds._valid_to,
        feeds._is_current
    FROM {{ ref('dim_agency') }} AS agency
    INNER JOIN member_schedule_feeds AS feeds
        ON agency.feed_key = feeds.key
)

SELECT * FROM tides_agency
