WITH external_operating_expenses_by_function AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__operating_expenses_by_function') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_operating_expenses_by_function
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_expenses_by_function AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    agency_voms,
    city,
    facility_maintenance,
    facility_maintenance_1,
    general_administration,
    general_administration_1,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    primary_uza_population,
    reduced_reporter_expenses,
    reduced_reporter_expenses_1,
    report_year,
    reporter_type,
    separate_report_amount,
    separate_report_amount_1,
    state,
    total,
    total_questionable,
    type_of_service,
    vehicle_maintenance,
    vehicle_maintenance_1,
    vehicle_operations,
    vehicle_operations_1,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_function
