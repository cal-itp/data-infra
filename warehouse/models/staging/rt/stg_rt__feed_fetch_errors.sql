WITH source AS (
    SELECT * FROM {{ source('sentry_external_tables', 'events') }}
),

latest AS (
    SELECT *
    FROM source
    WHERE ts = (SELECT MAX(ts) FROM source)
),

stg_rt__feed_fetch_errors AS (
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
    FROM latest
)

SELECT * FROM stg_rt__feed_fetch_errors
