{{ config(materialized='table') }}

WITH implemented_checks AS (
    SELECT *
    FROM {{ ref('fct_implemented_checks') }}
),

assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
    WHERE assessed
),

schedule_feed_checks AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_feed_guideline_checks') }}
),

rt_feed_checks AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_feed_guideline_checks') }}
),

schedule_url_checks AS (
    SELECT *
    FROM {{ ref('fct_daily_schedule_url_guideline_checks') }}
),

rt_url_checks AS (
    SELECT *
    FROM {{ ref('fct_daily_rt_url_guideline_checks') }}
),

organization_checks AS (
    SELECT * FROM {{ ref('fct_daily_organization_guideline_checks') }}
),

idx AS (
    SELECT
        implemented_checks.*,
        assessed_entities.*
    FROM implemented_checks
    CROSS JOIN assessed_entities
),

fct_daily_guideline_checks AS (
    SELECT
        {{ dbt_utils.surrogate_key([
            'idx.date',
            'idx.organization_key',
            'idx.service_key',
            'idx.gtfs_service_data_key',
            'idx.gtfs_dataset_key',
            'idx.schedule_feed_key',
            'idx.check']) }} AS key,
        idx.date,
        idx.organization_name,
        idx.service_name,
        idx.gtfs_dataset_name,
        idx.gtfs_dataset_type,
        idx.base64_url,
        idx.organization_key,
        idx.service_key,
        idx.gtfs_service_data_key,
        idx.gtfs_dataset_key,
        idx.schedule_feed_key,
        idx.feature,
        idx.check,
        COALESCE(
            schedule_feed_checks.status,
            rt_feed_checks.status,
            schedule_url_checks.status,
            rt_url_checks.status,
            organization_checks.status
        ) AS status
    FROM idx
    LEFT JOIN schedule_feed_checks
        ON idx.date = schedule_feed_checks.date
        AND idx.schedule_feed_key = schedule_feed_checks.feed_key
        AND idx.check = schedule_feed_checks.check
    LEFT JOIN rt_feed_checks
        ON idx.date = rt_feed_checks.date
        AND idx.base64_url = rt_feed_checks.base64_url
        AND idx.check = rt_feed_checks.check
    LEFT JOIN schedule_url_checks
        ON idx.date = schedule_url_checks.date
        AND idx.base64_url = schedule_url_checks.base64_url
        AND idx.check = schedule_url_checks.check
    LEFT JOIN rt_url_checks
        ON idx.date = rt_url_checks.date
        AND idx.base64_url = rt_url_checks.base64_url
        AND idx.check = rt_url_checks.check
    LEFT JOIN organization_checks
        ON idx.date = organization_checks.date
        AND idx.organization_key = organization_checks.organization_key
)

SELECT * FROM fct_daily_guideline_checks
