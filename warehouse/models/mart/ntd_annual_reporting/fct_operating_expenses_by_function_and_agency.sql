WITH staging_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function_and_agency') }}
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
        staging_operating_expenses_by_function_and_agency.*,
        current_dim_organizations.caltrans_district
    FROM staging_operating_expenses_by_function_and_agency
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    city,
    max_agency_voms,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    state,
    sum_facility_maintenance,
    sum_general_administration,
    sum_reduced_reporter_expenses,
    sum_separate_report_amount,
    sum_vehicle_maintenance,
    sum_vehicle_operations,
    total,
    caltrans_district,
    dt,
    execution_ts
FROM fct_operating_expenses_by_function_and_agency
