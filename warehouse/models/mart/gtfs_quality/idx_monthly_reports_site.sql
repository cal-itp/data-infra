{{ config(materialized='table') }}

WITH dataset_map AS (
    SELECT *,
    DATE_TRUNC(date, MONTH) AS date_start
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    -- filter to only organizations that are supposed to be assessed
    WHERE reports_site_assessed
),

assessed_entities AS (
    SELECT *
    FROM dataset_map
    -- pull the list of organizations on the *last* day of each month to get final snapshot
    WHERE LAST_DAY(date, MONTH) = date
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
),

dim_routes AS (
    SELECT *
    FROM {{ ref('dim_routes') }}
),

dim_stops AS (
    SELECT *
    FROM {{ ref('dim_stops') }}
),

dim_feed_info AS (
    SELECT *
    FROM {{ ref('dim_feed_info') }}
),

service_summary AS (
    SELECT
        *,
        LAST_DAY(activity_date, MONTH) AS month_last_date
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

summarize_feed_info AS (
    SELECT
        date,
        organization_source_record_id,
        MIN(feed_end_date) AS earliest_feed_end_date
    FROM schedule_assessed
    LEFT JOIN dim_feed_info
        ON schedule_assessed.schedule_feed_key = dim_feed_info.feed_key
    GROUP BY 1, 2
),

make_distinct AS (SELECT DISTINCT
    date_start,
    organization_itp_id,
    gtfs_dataset_name,
    {{ from_url_safe_base64('base64_url') }} AS string_url
FROM dataset_map
),

month_reports_urls AS (
    SELECT date_start, organization_itp_id, ARRAY_AGG(STRUCT(gtfs_dataset_name, string_url)) AS feeds
    FROM make_distinct
    GROUP BY 1, 2
),

idx_pending_urls AS (
    -- select distinct to drop services feeds etc., we only want organizations
    SELECT DISTINCT
        -- day after the last of the month is the first of the following month
        DATE_ADD(assessed_orgs.date, INTERVAL 1 DAY) AS publish_date,
        DATE_TRUNC(assessed_orgs.date, MONTH) AS date_start,
        -- above we filtered to only last day of the month already
        assessed_orgs.date AS date_end,
        assessed_orgs.organization_itp_id,
        assessed_orgs.organization_name,
        assessed_orgs.organization_source_record_id,
        assessed_orgs.organization_key,
        COALESCE(check_rt.has_rt, FALSE) AS has_rt,
        route_count.route_ct,
        stop_count.stop_ct,
        no_service_days.no_service_days_ct,
        earliest_feed_end_date,
        org_dim.website AS organization_website
    FROM schedule_assessed AS assessed_orgs
    LEFT JOIN check_rt
        USING (date, organization_source_record_id)
    LEFT JOIN route_count
        USING (date, organization_source_record_id)
    LEFT JOIN stop_count
        USING (date, organization_source_record_id)
    LEFT JOIN no_service_days
        USING (date, organization_source_record_id)
    LEFT JOIN summarize_feed_info
        USING (date, organization_source_record_id)
    LEFT JOIN dim_organizations AS org_dim
        ON assessed_orgs.organization_key = org_dim.key
    -- don't add rows until the month in which the report will be generated
    -- i.e., do not add January rows until February has started
    WHERE date < CURRENT_DATE()
),

idx_monthly_reports_site AS (
    -- split out since it's impossible to select distinct an array
    SELECT idx_pending_urls.*, month_reports_urls.feeds
    FROM idx_pending_urls
    LEFT JOIN month_reports_urls
        USING (date_start, organization_itp_id)
)

SELECT * FROM idx_monthly_reports_site
