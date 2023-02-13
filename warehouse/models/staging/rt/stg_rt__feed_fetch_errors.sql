{{
    config(
        materialized='incremental',
        unique_key='id',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'dt',
            'data_type': 'date',
            'granularity': 'day',
        },
        partitions=['current_date()'],
        cluster_by='groupid',
    )
}}

WITH source AS (
    SELECT * FROM {{ source('sentry_external_tables', 'events') }}
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
    FROM source
)

SELECT * FROM stg_rt__feed_fetch_errors
