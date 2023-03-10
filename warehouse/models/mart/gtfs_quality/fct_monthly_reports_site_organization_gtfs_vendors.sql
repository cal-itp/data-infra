{{ config(materialized='table') }}

WITH assessed_entities AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
    -- filter to only organizations that are supposed to be assessed
    WHERE reports_site_assessed
),

gtfs_generation_components AS (
    SELECT *
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
        assessed_entities.organization_name, assessed_entities.organization_key,
        assessed_entities.organization_itp_id,
        DATE_TRUNC(assessed_entities.date, MONTH) AS date_start,
        gtfs_generation_components.component_name, gtfs_generation_components.product_name,
        gtfs_generation_components.product_vendor_organization_source_record_id
    FROM assessed_entities
    LEFT JOIN gtfs_generation_components
        ON assessed_entities.service_key = gtfs_generation_components.service_key
),

orgs_joined AS (
    SELECT
        entities_components_joined.*,
        dim_orgs.name, dim_orgs.organization_type
    FROM entities_components_joined
    LEFT JOIN dim_orgs
        ON entities_components_joined.product_vendor_organization_source_record_id = dim_orgs.source_record_id
),

to_aggregate AS (
    SELECT
        *,
        CASE
            -- manually coded to relevance to GTFS Schedule and RT
            WHEN component_name IN ('GTFS generation', 'Scheduling (Fixed-route)')
                THEN 'schedule_vendors'
            WHEN component_name IN ('Real-time info', 'Arrival predictions',
             'GTFS-rt vehicles/trips', 'GTFS Alerts Publication')
                THEN 'rt_vendors'
        END AS reports_vendor_type,
        CASE
            WHEN name IS NOT NULL
                -- generally surface name of vendor, not product
                THEN name
            WHEN product_name IN ('TO CONFIRM', 'In house activity')
            -- no vendor per se, but arguably useful info to surface on reports site
                THEN product_name
        END AS reports_vendor_name
    FROM orgs_joined
),

fct_monthly_reports_site_organization_gtfs_vendors AS (
    SELECT
    organization_name, organization_key, organization_itp_id,
    date_start, reports_vendor_type,
    ARRAY_AGG(DISTINCT reports_vendor_name) AS vendor_names
    FROM to_aggregate
    WHERE reports_vendor_name IS NOT NULL
    GROUP BY 1, 2, 3, 4, 5
)

SELECT * FROM fct_monthly_reports_site_organization_gtfs_vendors

--transform to have arrays of "schedule vendors" and "rt vendors" that can be joined to idx??
