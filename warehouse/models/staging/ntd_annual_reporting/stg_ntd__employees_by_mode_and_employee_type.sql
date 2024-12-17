WITH external_employees_by_mode_and_employee_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__employees_by_mode_and_employee_type') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_employees_by_mode_and_employee_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__employees_by_mode_and_employee_type AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    agency_voms,
    capital_labor_count,
    capital_labor_count_q,
    capital_labor_hours,
    capital_labor_hours_q,
    city,
    facility_maintenance_count,
    facility_maintenance_count_q,
    facility_maintenance_hours,
    facility_maintenance_hours_q,
    full_or_part_time,
    general_administration_count,
    general_administration_count_q,
    general_administration_hours,
    general_administration_hours_q,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    primary_uza_population,
    report_year,
    state,
    total_employee_count,
    total_employee_count_q,
    total_hours,
    total_hours_q,
    type_of_service,
    uace_code,
    uza_name,
    vehicle_maintenance_count,
    vehicle_maintenance_count_q,
    vehicle_maintenance_hours,
    vehicle_maintenance_hours_q,
    vehicle_operations_count,
    vehicle_operations_count_q,
    vehicle_operations_hours,
    vehicle_operations_hours_q,
    dt,
    execution_ts
FROM stg_ntd__employees_by_mode_and_employee_type
