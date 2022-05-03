{{ config(materialized='table') }}

WITH error_stdout AS (
    SELECT *
    FROM {{ source('gtfs_rt_logs', 'stdout') }}
    WHERE textPayload LIKE "%error fetching url%"
),

calitp_feeds AS (
    SELECT
        itp_id,
        url_number,
        gtfs_rt_service_alerts_url,
        gtfs_rt_trip_updates_url,
        gtfs_rt_vehicle_positions_url,
        PARSE_DATE(
            '%Y-%m-%d',
            REGEXP_EXTRACT(_FILE_NAME, ".*/([0-9]+-[0-9]+-[0-9]+)")
        ) AS calitp_extracted_at
    FROM {{ source('gtfs_schedule_history', 'calitp_feeds') }}
),

gtfs_rt_fact_daily_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_rt_fact_daily_feeds') }}
),

calitp_feeds_long AS (
    SELECT
        *,
        REGEXP_EXTRACT(url_type, r"gtfs_rt_(.*)_url") AS type
    FROM calitp_feeds
    UNPIVOT(url FOR url_type IN (gtfs_rt_service_alerts_url, gtfs_rt_trip_updates_url, gtfs_rt_vehicle_positions_url))
),

download_issues AS (
    SELECT DISTINCT
        -- make a tick identifier to remove duplicates from MTC 511 feeds
        -- they all use the same service alerts URL
        -- and so they all have download errors at slightly different timestamps
        -- but they all came from the same "tick"
        -- so dedupe on tick here to avoid fanout later
        TIMESTAMP_ADD(
            TIMESTAMP_TRUNC(timestamp, MINUTE),
            -- use floor to estimate tick so that the resulting rounded timestamp
            -- will have the same minute, hour, date as the original
            INTERVAL CAST((FLOOR(EXTRACT(SECOND FROM timestamp) / 20) * 20) AS INT) SECOND
        ) AS tick_timestamp,
        -- this URL contains API keys
        REGEXP_EXTRACT(
            textPayload,
            -- extract the full URL
            -- it's a string that doesn't contain spaces hence \S
            r"error fetching url (\S+): ")
        AS unsafe_url,
        REGEXP_EXTRACT(
            textPayload,
            -- extract the error itself
            -- we know it comes right after the URL
            -- plus colon and single space
            r"error fetching url [\S]+: (.+)")
        AS error
    -- note that we've moved the logs to gtfs_rt_logs.stdout, since the table name can't be changed
    FROM error_stdout
),

gtfs_rt_extraction_errors AS (
    SELECT
        T1.tick_timestamp,
        T2.itp_id AS calitp_itp_id,
        T2.url_number AS calitp_url_number,
        T2.type,
        T1.error,
        T3.url AS raw_url
    FROM download_issues AS T1
    LEFT JOIN calitp_feeds_long AS T2
        ON (
            T1.unsafe_url = T2.url
            AND EXTRACT(DATE from T1.tick_timestamp)= T2.calitp_extracted_at
        )
    LEFT JOIN gtfs_rt_fact_daily_feeds AS T3
        ON (
            T2.itp_id = T3.calitp_itp_id
            AND T2.url_number = T3.calitp_url_number
            AND T2.calitp_extracted_at = T3.date
            AND T2.type = T3.type
        )
)

SELECT * FROM gtfs_rt_extraction_errors
