{{ config(materialized='table') }}

WITH stdout AS (
    SELECT *
    FROM {{ source('gtfs_rt_logs', 'gtfs_schedule_fact_daily_feeds') }}
),

download_issues AS (
    SELECT
        textPayload,
        timestamp,
        REGEXP_EXTRACT(
            textPayload,
            "error fetching url ([\S+]): ")
            AS url,
    -- note that we've moved the logs to gtfs_rt_logs.stdout, since the table name can't be changed
    FROM `cal-itp-data-infra.gtfs_rt_logs.stdout`
    WHERE textPayload LIKE "%error fetching url%"
)
