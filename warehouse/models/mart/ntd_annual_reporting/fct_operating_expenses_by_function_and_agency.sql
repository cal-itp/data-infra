WITH staging_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function_and_agency') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_operating_expenses_by_function_and_agency AS (
    SELECT
        staging_operating_expenses_by_function_and_agency.*,
        dim_organizations.caltrans_district
    FROM staging_operating_expenses_by_function_and_agency
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_operating_expenses_by_function_and_agency.report_year = 2022 THEN
                staging_operating_expenses_by_function_and_agency.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_operating_expenses_by_function_and_agency.ntd_id = dim_organizations.ntd_id
        END
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
