WITH staging_maintenance_facilities AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_maintenance_facilities AS (
    SELECT
        staging_maintenance_facilities.*,
        dim_organizations.caltrans_district
    FROM staging_maintenance_facilities
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_maintenance_facilities.report_year = 2022 THEN
                staging_maintenance_facilities.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_maintenance_facilities.ntd_id = dim_organizations.ntd_id
        END
)

SELECT
    _200_to_300_vehicles,
    _200_to_300_vehicles_1,
    agency,
    agency_voms,
    city,
    heavy_maintenance_facilities,
    heavy_maintenance_facilities_1,
    leased_by_pt_provider,
    leased_by_pt_provider_1,
    leased_by_public_agency,
    leased_by_public_agency_1,
    leased_from_a_private_entity,
    leased_from_a_private_entity_1,
    leased_from_a_public_entity,
    leased_from_a_public_entity_1,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    over_300_vehicles,
    over_300_vehicles_questionable,
    owned,
    owned_questionable,
    owned_by_pt_provider,
    owned_by_pt_provider_1,
    owned_by_public_agency,
    owned_by_public_agency_1,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_facilities,
    total_maintenance_facilities,
    type_of_service,
    uace_code,
    under_200_vehicles,
    under_200_vehicles_1,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_maintenance_facilities
