WITH assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

idx_monthly_reports_site AS (
    SELECT DISTINCT
        CAST(date AS DATE) AS date_start,
        organization_itp_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(date, MONTH) AS date_end,
        DATE_ADD(LAST_DAY(date, MONTH), INTERVAL 1 DAY) AS publish_date
    FROM assessed_entities
    WHERE
        DATE_TRUNC(date, MONTH) = date
        AND reports_site_assessed
        -- don't add rows until the month in which the report will be generated
        -- i.e., do not add January rows until February has started
        AND DATE_ADD(LAST_DAY(date, MONTH), INTERVAL 1 DAY) <= CURRENT_DATE()
)

SELECT * FROM idx_monthly_reports_site
