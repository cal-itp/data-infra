WITH external_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__operating_expenses_by_function_and_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_operating_expenses_by_function_and_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM get_latest_extract
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
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_function_and_agency
