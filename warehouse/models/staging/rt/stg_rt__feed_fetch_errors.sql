{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        partitions=['current_date()'],
        cluster_by='job_type',
    )
}}

WITH latest AS (
    {% set yesterday = modules.datetime.date.today() - modules.datetime.timedelta(days=1) %}

    SELECT *
    FROM cal-itp-data-infra.external_sentry_error_logs.events
    WHERE dt = yesterday
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
