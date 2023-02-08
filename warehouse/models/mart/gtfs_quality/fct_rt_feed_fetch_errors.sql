{{ config(materialized='table') }}

WITH fct_rt_feed_fetch_errors AS (
    SELECT
        id,
        event_type,
        groupid,
        eventid,
        projectid,
        message,
        title,
        location,
        culprit,
        user,
        tags,
        platform,
        datecreated,
        crashfile,
        dt,
        ts
    FROM {{ ref('stg_rt__feed_fetch_errors') }}
)

SELECT * FROM fct_rt_feed_fetch_errors
