{{ config(materialized='table') }}

WITH fct_daily_schedule_feed_validation_notices AS (
    SELECT * FROM {{ ref('fct_daily_schedule_feed_validation_notices') }}
),

int_gtfs__organization_dataset_map AS (

    SELECT *,
        DATE_ADD(LAST_DAY(date, MONTH), INTERVAL 1 DAY) AS publish_date
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE reports_site_assessed

),

fct_monthly_reports_site_organization_validation_codes AS (
    SELECT DISTINCT
        {{ dbt_utils.surrogate_key(['organization_source_record_id',
                                    'publish_date',
                                    'code',
        ]) }} AS key,
        organization_name,
        organization_source_record_id,
        organization_itp_id,
        publish_date,
        code,
        severity,
        validation_validator_version
    FROM fct_daily_schedule_feed_validation_notices AS notices
    INNER JOIN int_gtfs__organization_dataset_map AS orgs
        ON notices.date = orgs.date
        AND notices.feed_key = orgs.schedule_feed_key
    WHERE total_notices > 0
    QUALIFY validation_validator_version = MAX(validation_validator_version)
        OVER (PARTITION BY publish_date, organization_source_record_id)

)

SELECT * FROM fct_monthly_reports_site_organization_validation_codes
