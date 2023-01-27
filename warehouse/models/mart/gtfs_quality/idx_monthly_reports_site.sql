{{ config(materialized='table') }}

WITH assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    -- filter to only organizations that are supposed to be assessed
    WHERE reports_site_assessed
        -- pull the list of organizations on the *last* day of each month to get final snapshot
        AND LAST_DAY(date, MONTH) = date
),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
),

service_summary AS (
    SELECT
        *,
        LAST_DAY(service_date, MONTH) AS month_last_date
    FROM {{ ref('fct_daily_reports_site_organization_scheduled_service_summary') }}
),

schedule_assessed AS (
    SELECT *
    FROM assessed_entities
    WHERE gtfs_dataset_type = "schedule"
),

-- TODO: technically this does not guarantee that this is the RT associated
-- with the assessed schedule feed; however, this will only get feeds that are
-- "assessed for reports site" so they have to be customer-facing
check_rt AS (
    SELECT
        date,
        organization_source_record_id,
        COUNT(*) > 0 AS has_rt
    FROM assessed_entities
    -- filter out rows where dataset type is null
    WHERE COALESCE(gtfs_dataset_type, "schedule") != "schedule"
        AND organization_source_record_id IS NOT NULL
    GROUP BY 1, 2
),

route_count AS (
    SELECT
        date,
        organization_source_record_id,
        -- TODO: technically this is fragile
        -- if an organization has multiple routes with the same ID across different feeds
        COUNT(DISTINCT route_id) AS route_ct
    FROM schedule_assessed
    LEFT JOIN dim_routes
        ON schedule_assessed.schedule_feed_key = dim_routes.feed_key
    GROUP BY 1, 2
),

stop_count AS (
    SELECT
        date,
        organization_source_record_id,
        -- TODO: technically this is fragile
        -- if an organization has multiple stops with the same ID across different feeds
        -- TODO: we could add a flag here for duplicate stop IDs if we want
        COUNT(DISTINCT stop_id) AS stop_ct
    FROM schedule_assessed
    LEFT JOIN dim_stops
        ON schedule_assessed.schedule_feed_key = dim_stops.feed_key
    GROUP BY 1, 2
),

no_service_days AS (
    SELECT
        month_last_date AS date,
        organization_source_record_id,
        COUNTIF(ttl_service_hours = 0) AS no_service_days_ct,
    FROM service_summary
    GROUP BY 1, 2
),

idx_monthly_reports_site AS (
    -- select distinct to drop services feeds etc., we only want organizations
    SELECT DISTINCT
        -- day after the last of the month is the first of the following month
        DATE_ADD(orgs.date, INTERVAL 1 DAY) AS publish_date,
        DATE_TRUNC(orgs.date, MONTH) AS date_start,
        -- above we filtered to only last day of the month already
        orgs.date AS date_end,
        orgs.organization_itp_id,
        orgs.organization_name,
        orgs.organization_source_record_id,
        COALESCE(check_rt.has_rt, FALSE) AS has_rt,
        route_count.route_ct,
        stop_count.stop_ct,
        no_service_days.no_service_days_ct,
    -- we only want reports where there is some schedule data
    FROM schedule_assessed AS orgs
    LEFT JOIN check_rt
        USING (date, organization_source_record_id)
    LEFT JOIN route_count
        USING (date, organization_source_record_id)
    LEFT JOIN stop_count
        USING (date, organization_source_record_id)
    LEFT JOIN no_service_days
        USING (date, organization_source_record_id)
    -- don't add rows until the month in which the report will be generated
    -- i.e., do not add January rows until February has started
    WHERE date < CURRENT_DATE()
)

SELECT * FROM idx_monthly_reports_site
