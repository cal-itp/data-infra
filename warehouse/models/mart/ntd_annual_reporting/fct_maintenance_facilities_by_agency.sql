WITH staging_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_maintenance_facilities_by_agency AS (
    SELECT
        stg.max_agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.max_city AS city,
        stg.max_state AS state,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_200_to_300_vehicles,
        stg.sum_heavy_maintenance_facilities,
        stg.sum_leased_by_pt_provider,
        stg.sum_leased_by_public_agency,
        stg.sum_leased_from_a_private_entity,
        stg.sum_leased_from_a_public_entity,
        stg.sum_over_300_vehicles,
        stg.sum_owned,
        stg.sum_owned_by_pt_provider,
        stg.sum_owned_by_public_agency,
        stg.sum_total_facilities,
        stg.sum_under_200_vehicles,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_maintenance_facilities_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_maintenance_facilities_by_agency
