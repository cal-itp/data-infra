-- description for this table got too long, don't persist to BQ
{{ config(materialized='table', persist_docs={"relation": false, "columns": true}) }}

WITH implemented_checks AS (
    SELECT *
    FROM {{ ref('fct_implemented_checks') }}
),

assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
    WHERE guidelines_assessed
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

gtfs_dataset_checks AS (
    SELECT * FROM {{ ref('fct_daily_gtfs_dataset_guideline_checks') }}
),

service_checks AS (
    SELECT * FROM {{ ref('fct_daily_service_guideline_checks') }}
),

gtfs_service_data_checks AS (
    SELECT * FROM {{ ref('fct_daily_gtfs_service_data_guideline_checks') }}
),

idx AS (
    SELECT
        implemented_checks.*,
        assessed_entities.*
    FROM implemented_checks
    CROSS JOIN assessed_entities
),

int_gtfs_quality__guideline_checks_long AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key([
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
        idx.organization_source_record_id,
        idx.service_key,
        idx.gtfs_service_data_key,
        idx.gtfs_dataset_key,
        idx.schedule_feed_key,
        idx.feature,
        idx.check,
        idx.entity,
        COALESCE(
            schedule_feed_checks.status,
            rt_feed_checks.status,
            schedule_url_checks.status,
            rt_url_checks.status,
            organization_checks.status,
            gtfs_dataset_checks.status,
            service_checks.status,
            gtfs_service_data_checks.status
        ) AS status,
        CASE
            WHEN schedule_feed_checks.status IS NOT NULL THEN idx.entity = {{ schedule_feed() }}
            WHEN rt_feed_checks.status IS NOT NULL THEN idx.entity = {{ rt_feed() }}
            WHEN schedule_url_checks.status IS NOT NULL THEN idx.entity = {{ schedule_url() }}
            WHEN rt_url_checks.status IS NOT NULL THEN idx.entity = {{ rt_url() }}
            WHEN organization_checks.status IS NOT NULL THEN idx.entity = {{ organization() }}
            WHEN gtfs_dataset_checks.status IS NOT NULL THEN idx.entity = {{ gtfs_dataset() }}
            WHEN service_checks.status IS NOT NULL THEN idx.entity = {{ service() }}
            WHEN gtfs_service_data_checks.status IS NOT NULL THEN idx.entity = {{ gtfs_service_data() }}
        END AS matches_entity,
        CASE WHEN schedule_feed_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN rt_feed_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN schedule_url_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN rt_url_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN organization_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN gtfs_dataset_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN service_checks.status IS NOT NULL THEN 1 ELSE 0 END
        + CASE WHEN gtfs_service_data_checks.status IS NOT NULL THEN 1 ELSE 0 END
        AS num_check_sources,
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
        AND idx.check = organization_checks.check
    LEFT JOIN gtfs_dataset_checks
        ON idx.date = gtfs_dataset_checks.date
        AND idx.gtfs_dataset_key = gtfs_dataset_checks.gtfs_dataset_key
        AND idx.check = gtfs_dataset_checks.check
    LEFT JOIN service_checks
        ON idx.date = service_checks.date
        AND idx.service_key = service_checks.service_key
        AND idx.check = service_checks.check
    LEFT JOIN gtfs_service_data_checks
        ON idx.date = gtfs_service_data_checks.date
        AND idx.gtfs_service_data_key = gtfs_service_data_checks.gtfs_service_data_key
        AND idx.check = gtfs_service_data_checks.check
)

SELECT * FROM int_gtfs_quality__guideline_checks_long
