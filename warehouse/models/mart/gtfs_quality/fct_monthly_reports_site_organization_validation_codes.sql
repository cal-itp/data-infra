{{ config(materialized='table') }}

WITH fct_daily_schedule_feed_validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
),

idx_monthly_reports_site AS (
    SELECT *
    FROM {{ ref('idx_monthly_reports_site') }}
),

int_gtfs__organization_dataset_map AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE reports_site_assessed
),

validator_details AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__schedule_validator_rule_details_unioned') }}
),

fct_monthly_reports_site_organization_validation_codes AS (
    SELECT DISTINCT
        {{ dbt_utils.surrogate_key(['idx.organization_source_record_id',
                                    'idx.publish_date',
                                    'notices.code',
        ]) }} AS key,
        idx.organization_name,
        idx.organization_source_record_id,
        idx.organization_itp_id,
        idx.publish_date,
        notices.code,
        notices.severity,
        validator_details.human_readable_description,
        notices.validation_validator_version
    FROM fct_daily_schedule_feed_validation_notices AS notices
    INNER JOIN int_gtfs__organization_dataset_map AS orgs
        ON notices.date = orgs.date
        AND notices.feed_key = orgs.schedule_feed_key
    INNER JOIN idx_monthly_reports_site AS idx
        ON notices.date BETWEEN idx.date_start AND idx.date_end
        AND orgs.organization_source_record_id = idx.organization_source_record_id
    LEFT JOIN validator_details
        ON notices.code = validator_details.code
        AND notices.validation_validator_version = validator_details.version
    WHERE total_notices > 0
    QUALIFY validation_validator_version = MAX(validation_validator_version)
        OVER (PARTITION BY publish_date, organization_source_record_id)

)

SELECT * FROM fct_monthly_reports_site_organization_validation_codes
