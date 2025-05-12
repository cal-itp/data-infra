WITH staging_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function_and_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_expenses_by_function_and_agency AS (
    SELECT
        stg.agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_facility_maintenance,
        stg.sum_general_administration,
        stg.sum_reduced_reporter_expenses,
        stg.sum_separate_report_amount,
        stg.sum_vehicle_maintenance,
        stg.sum_vehicle_operations,
        stg.total,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_function_and_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_expenses_by_function_and_agency
