WITH assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
    WHERE reports_site_assessed
        AND gtfs_dataset_type = "schedule"
        -- ITP ID is necessary to generate URL for reports site
        AND organization_itp_id IS NOT NULL
),

idx_monthly_reports_site AS (
    -- select distinct to drop services feeds etc., we only want organizations
    SELECT DISTINCT
        DATE_TRUNC(date, MONTH) AS date_start,
        organization_itp_id,
        organization_name,
        organization_source_record_id,
        LAST_DAY(date, MONTH) AS date_end,
        DATE_ADD(LAST_DAY(date, MONTH), INTERVAL 1 DAY) AS publish_date
    FROM assessed_entities
    WHERE
        -- pull the list of organizations on the *last* day of each month to get final snapshot
        LAST_DAY(date, MONTH) = date
        -- don't add rows until the month in which the report will be generated
        -- i.e., do not add January rows until February has started
        AND date < CURRENT_DATE()
)

SELECT * FROM idx_monthly_reports_site
