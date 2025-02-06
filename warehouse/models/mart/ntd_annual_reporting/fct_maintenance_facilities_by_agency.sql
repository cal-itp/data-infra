WITH staging_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities_by_agency') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_maintenance_facilities_by_agency AS (
    SELECT
        staging_maintenance_facilities_by_agency.*,
        dim_organizations.caltrans_district
    FROM staging_maintenance_facilities_by_agency
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_maintenance_facilities_by_agency.report_year = 2022 THEN
                staging_maintenance_facilities_by_agency.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_maintenance_facilities_by_agency.ntd_id = dim_organizations.ntd_id
        END
)

SELECT
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_200_to_300_vehicles,
    sum_heavy_maintenance_facilities,
    sum_leased_by_pt_provider,
    sum_leased_by_public_agency,
    sum_leased_from_a_private_entity,
    sum_leased_from_a_public_entity,
    sum_over_300_vehicles,
    sum_owned,
    sum_owned_by_pt_provider,
    sum_owned_by_public_agency,
    sum_total_facilities,
    sum_under_200_vehicles,
    caltrans_district,
    dt,
    execution_ts
FROM fct_maintenance_facilities_by_agency
