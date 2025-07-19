{{ config(materialized='table') }}

WITH idx_monthly_reports_site AS (
    SELECT *
    FROM {{ ref('idx_monthly_reports_site') }}
),

checks AS (
    SELECT date,
           organization_source_record_id,
           feature,
           check,
           reports_status,
           percentage,
           is_manual,
           reports_order,
    FROM {{ ref('fct_daily_organization_combined_guideline_checks') }}
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

fct_monthly_reports_site_organization_guideline_checks AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['idx.publish_date',
            'idx.organization_source_record_id',
            'dates.sample_dates',
            'checks.check']) }} AS key,
        idx.organization_name,
        dates.sample_dates AS date_checked,
        idx.organization_source_record_id,
        idx.organization_itp_id,
        idx.publish_date,
        checks.feature,
        checks.check,
        checks.reports_status,
        checks.percentage,
        checks.is_manual,
        checks.reports_order
    FROM idx_monthly_reports_site AS idx
    LEFT JOIN generate_biweekly_dates AS dates
        USING (publish_date)
    -- Exclude organization + date combos that have no checks
    INNER JOIN checks
        ON idx.organization_source_record_id = checks.organization_source_record_id
        AND dates.sample_dates = checks.date
)

SELECT * FROM fct_monthly_reports_site_organization_guideline_checks
