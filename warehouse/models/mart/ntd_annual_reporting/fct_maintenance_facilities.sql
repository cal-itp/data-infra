WITH staging_maintenance_facilities AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_maintenance_facilities AS (
    SELECT
        stg.ntd_id,
        stg.agency,
        stg.report_year,
        stg.city,
        stg.state,
        stg._200_to_300_vehicles,
        stg._200_to_300_vehicles_1,
        stg.agency_voms,
        stg.heavy_maintenance_facilities,
        stg.heavy_maintenance_facilities_1,
        stg.leased_by_pt_provider,
        stg.leased_by_pt_provider_1,
        stg.leased_by_public_agency,
        stg.leased_by_public_agency_1,
        stg.leased_from_a_private_entity,
        stg.leased_from_a_private_entity_1,
        stg.leased_from_a_public_entity,
        stg.leased_from_a_public_entity_1,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.organization_type,
        stg.over_300_vehicles,
        stg.over_300_vehicles_questionable,
        stg.owned,
        stg.owned_questionable,
        stg.owned_by_pt_provider,
        stg.owned_by_pt_provider_1,
        stg.owned_by_public_agency,
        stg.owned_by_public_agency_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_facilities,
        stg.total_maintenance_facilities,
        stg.type_of_service,
        stg.uace_code,
        stg.under_200_vehicles,
        stg.under_200_vehicles_1,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_maintenance_facilities AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_maintenance_facilities
