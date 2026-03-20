WITH
current_organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

bridge_organizations_x_headquarters_county_geography_latest AS (
    SELECT * FROM {{ ref('bridge_organizations_x_headquarters_county_geography') }}
    WHERE _is_current
),

dim_county_geography_latest AS (
    SELECT * FROM {{ ref('dim_county_geography') }}
    WHERE _is_current
),

dim_organizations_latest_with_caltrans_district AS (
    SELECT
        co.key,
        co.source_record_id,
        co.name,
        co.organization_type,
        co.roles,
        co.itp_id,
        co.ntd_agency_info_key,
        co.details,
        co.website,
        co.reporting_category,
        co.hubspot_company_record_id,
        co.gtfs_static_status,
        co.gtfs_realtime_status,
        co._deprecated__assessment_status,
        co.manual_check__contact_on_website,
        co.alias,
        co.is_public_entity,
        co.public_currently_operating,
        co.public_currently_operating_fixed_route,
        co.ntd_id,
        co.ntd_id_2022,
        co.rtpa_key,
        co.rtpa_name,
        co.mpo_key,
        co.mpo_name,

        dcgl.caltrans_district,
        dcgl.caltrans_district_name,

        co._is_current,
        co._valid_from,
        co._valid_to
    FROM current_organizations AS co
        LEFT JOIN bridge_organizations_x_headquarters_county_geography_latest ON co.key = bridge_organizations_x_headquarters_county_geography_latest.organization_key
        LEFT JOIN dim_county_geography_latest AS dcgl ON bridge_organizations_x_headquarters_county_geography_latest.county_geography_key = dcgl.key
)

SELECT * FROM dim_organizations_latest_with_caltrans_district
