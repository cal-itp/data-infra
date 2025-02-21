WITH staging_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_maintenance_facilities_by_agency.*,
        current_dim_organizations.caltrans_district
    FROM staging_maintenance_facilities_by_agency
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_maintenance_facilities_by_agency AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
