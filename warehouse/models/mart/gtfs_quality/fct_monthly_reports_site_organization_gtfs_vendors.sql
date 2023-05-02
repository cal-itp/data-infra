{{ config(materialized='table') }}

WITH assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
    -- filter to only organizations that are supposed to be assessed
    WHERE public_customer_facing_or_regional_subfeed_fixed_route
),

gtfs_generation_components AS (
    SELECT *,
    CASE
        -- manually coded to relevance to GTFS Schedule and RT
        WHEN component_name IN ('GTFS generation', 'Scheduling (Fixed-route)')
            THEN 'schedule_vendors'
        WHEN component_name IN ('Real-time info', 'Arrival predictions',
         'GTFS-rt vehicles/trips', 'GTFS Alerts Publication')
            THEN 'rt_vendors'
    END AS reports_vendor_type,
    CASE
        WHEN product_vendor_organization_name IS NOT NULL
            -- generally surface vendor_name of vendor, not product
            THEN product_vendor_organization_name
        WHEN product_name IN ('TO CONFIRM', 'In house activity')
        -- no vendor per se, but arguably useful info to surface on reports site
            THEN product_name
    END AS reports_vendor_name
    FROM {{ ref('dim_service_components') }}
    WHERE component_name IN
        ('GTFS generation', 'Scheduling (Fixed-route)', 'Real-time info',
        'Arrival predictions', 'GTFS-rt vehicles/trips', 'GTFS Alerts Publication')
),

dim_orgs AS (
    SELECT
        source_record_id, name, organization_type
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

entities_components_joined AS (
    SELECT DISTINCT
        assessed_entities.organization_name, assessed_entities.organization_source_record_id,
        assessed_entities.organization_itp_id,
        DATE_TRUNC(assessed_entities.date, MONTH) AS date_start,
        gtfs_generation_components.component_name, gtfs_generation_components.product_name,
        gtfs_generation_components.reports_vendor_name,
        gtfs_generation_components.reports_vendor_type,
        gtfs_generation_components.product_vendor_organization_source_record_id
    FROM assessed_entities
    LEFT JOIN gtfs_generation_components
        ON assessed_entities.service_key = gtfs_generation_components.service_key
),

orgs_joined AS (
    SELECT
        entities_components_joined.*,
        dim_orgs.name AS vendor_name,
        dim_orgs.organization_type AS vendor_organization_type
    FROM entities_components_joined
    LEFT JOIN dim_orgs
        ON entities_components_joined.product_vendor_organization_source_record_id = dim_orgs.source_record_id
),

vendor_type_agged AS (
    SELECT
    organization_name, organization_source_record_id, organization_itp_id,
    date_start, reports_vendor_type,
    ARRAY_AGG(DISTINCT reports_vendor_name) AS vendor_names
    FROM orgs_joined
    WHERE reports_vendor_name IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5
),

-- is there a more elegant way to do this?
filter_schedule AS (
    SELECT
    organization_name, organization_source_record_id, organization_itp_id,
    date_start, vendor_names AS schedule_vendors
    FROM vendor_type_agged
    WHERE reports_vendor_type = 'schedule_vendors'
),

filter_rt AS (
    SELECT
    organization_name, organization_source_record_id, organization_itp_id,
    date_start, vendor_names AS rt_vendors
    FROM vendor_type_agged
    WHERE reports_vendor_type = 'rt_vendors'
),

fct_monthly_reports_site_organization_gtfs_vendors AS (
    SELECT *
    FROM
    filter_schedule
    LEFT JOIN filter_rt
        USING (organization_name, organization_source_record_id, organization_itp_id,
        date_start)
)

SELECT * FROM fct_monthly_reports_site_organization_gtfs_vendors
