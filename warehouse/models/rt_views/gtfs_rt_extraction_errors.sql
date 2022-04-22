{{ config(materialized='table') }}

--TODO:
-- join to get itp id, url number, date
-- join to get safe url based on the above
-- add safe url, itp id, url number to final output

WITH error_stdout AS (
    SELECT *
    FROM {{ source('gtfs_rt_logs', 'gtfs_schedule_fact_daily_feeds') }}
    WHERE textPayload LIKE "%error fetching url%"
),

calitp_feeds AS (
    SELECT *, _FILE_NAME
    FROM {{ source('gtfs_rt_schedule_history',
    'calitp_feeds') }}
),

calitp_feeds_raw AS (
    SELECT *, _FILE_NAME
    FROM {{ source('gtfs_rt_schedule_history',
    'calitp_feeds') }}
),

download_issues AS (
    SELECT
        timestamp,
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
)
