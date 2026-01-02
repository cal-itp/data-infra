{{ config(materialized='table') }}

-- crosswalk helps label GTFS data products, schedule_gtfs_dataset_name,
-- to get geography columns available in dim_organizations and
-- also get NTD IDs associated with the GTFS operator
WITH dim_gtfs_datasets AS (
    SELECT
        name,
        analysis_name,
        source_record_id,
        regional_feed_type,
        _valid_from,
        private_dataset,
        data_quality_pipeline,
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE ( data_quality_pipeline IS TRUE
           AND private_dataset IS NOT TRUE
           --AND regional_feed_type != "Regional Precursor Feed"
           AND analysis_name IS NOT NULL
           AND name != "Bay Area 511 Regional Schedule"
           AND type = "schedule")
),

deduped_analysis_name AS (
    SELECT
        analysis_name,
        source_record_id,
        name,
        regional_feed_type,

    FROM dim_gtfs_datasets
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY source_record_id
        ORDER BY _valid_from DESC
    ) = 1
),

-- this one has services, but we are ignoring services for these joins
dim_provider_gtfs_data AS (
    SELECT *
    FROM {{ ref('dim_provider_gtfs_data') }}
),

deduped_provider AS (
    SELECT DISTINCT
        organization_name,
        schedule_source_record_id,

    FROM dim_provider_gtfs_data
    QUALIFY ROW_NUMBER() OVER(
        PARTITION BY schedule_source_record_id
        ORDER BY _valid_from DESC
    ) = 1
),


dim_organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

dim_county_geography AS (
    SELECT DISTINCT
        key,
        name,
        caltrans_district,
        caltrans_district_name,
    FROM {{ ref('dim_county_geography') }}
),

bridge_org_county AS (
    SELECT
        organization_key,
        county_geography_key,
    FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
),

orgs_with_geog AS (
    SELECT DISTINCT
        dim_organizations.source_record_id AS organization_source_record_id,
        dim_organizations.name AS organization_name,

        dim_county_geography.name AS county_name,
        dim_county_geography.caltrans_district,
        dim_county_geography.caltrans_district_name,

        dim_organizations.ntd_id,
        dim_organizations.ntd_id_2022,
        dim_organizations.rtpa_name,
        dim_organizations.mpo_name,

    FROM dim_organizations
    INNER JOIN bridge_org_county
        ON dim_organizations.key = bridge_org_county.organization_key
    INNER JOIN dim_county_geography
        ON bridge_org_county.county_geography_key = dim_county_geography.key
),

gtfs_to_orgs AS (
    SELECT
        orgs_with_geog.organization_name,
        orgs_with_geog.organization_source_record_id,
        deduped_provider.schedule_source_record_id,
        deduped_analysis_name.name AS schedule_gtfs_dataset_name,
        deduped_analysis_name.analysis_name,
        deduped_analysis_name.regional_feed_type,

        orgs_with_geog.county_name,
        orgs_with_geog.caltrans_district,
        orgs_with_geog.caltrans_district_name,

        orgs_with_geog.ntd_id,
        orgs_with_geog.ntd_id_2022,
        orgs_with_geog.rtpa_name,
        orgs_with_geog.mpo_name,

    FROM deduped_provider
    INNER JOIN deduped_analysis_name
        ON deduped_analysis_name.source_record_id = deduped_provider.schedule_source_record_id
    INNER JOIN orgs_with_geog
        ON deduped_provider.organization_name = orgs_with_geog.organization_name
    ORDER BY schedule_gtfs_dataset_name
)

SELECT * FROM gtfs_to_orgs
