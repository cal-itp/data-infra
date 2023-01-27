{{ config(materialized='table') }}

WITH files AS (
    SELECT *
    FROM {{ ref('fct_schedule_feed_files') }}
),

idx_monthly_reports_site AS (
    SELECT *
    FROM {{ ref('idx_monthly_reports_site') }}
),

int_gtfs__organization_dataset_map AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
),

generate_biweekly_dates AS (
    SELECT DISTINCT
        publish_date,
        sample_dates
    FROM idx_monthly_reports_site
    LEFT JOIN
        UNNEST(GENERATE_DATE_ARRAY(
            -- add a few days because otherwise it will always pick the first of the month,
            -- which may be disproportionately likely to have new feed published and thus issues
            DATE_ADD(CAST(date_start AS DATE), INTERVAL 3 DAY),
            CAST(date_end AS DATE), INTERVAL 2 WEEK)) AS sample_dates
),

check_files AS (
    SELECT *
    FROM idx_monthly_reports_site AS idx
    LEFT JOIN generate_biweekly_dates AS dates
    USING (publish_date)
    LEFT JOIN int_gtfs__organization_dataset_map AS map
        ON dates.sample_dates = map.date
        AND idx.organization_source_record_id = map.organization_source_record_id
)

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
        notices.validation_validator_version
    FROM fct_daily_schedule_feed_validation_notices AS notices
    INNER JOIN int_gtfs__organization_dataset_map AS orgs
        ON notices.date = orgs.date
        AND notices.feed_key = orgs.schedule_feed_key
    INNER JOIN idx_monthly_reports_site AS idx
        ON notices.date BETWEEN idx.date_start AND idx.date_end
        AND orgs.organization_source_record_id = idx.organization_source_record_id
    WHERE total_notices > 0
    QUALIFY validation_validator_version = MAX(validation_validator_version)
        OVER (PARTITION BY publish_date, organization_source_record_id)

)

SELECT * FROM fct_monthly_reports_site_organization_validation_codes
