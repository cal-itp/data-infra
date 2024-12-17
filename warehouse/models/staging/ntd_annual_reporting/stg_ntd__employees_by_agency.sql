WITH external_employees_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__employees_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_employees_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__employees_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    avgwagerate,
    count_capital_labor_count_q,
    count_capital_labor_hours_q,
    count_facility_maintenance_count_q,
    count_facility_maintenance_hours_q,
    count_general_administration_count_q,
    count_general_administration_hours_q,
    count_total_employee_count_q,
    count_total_employee_hours_q,
    count_vehicle_maintenance_count_q,
    count_vehicle_maintenance_hours_q,
    count_vehicle_operations_count_q,
    count_vehicle_operations_hours_q,
    max_agency_voms_1,
    max_city_1,
    max_mode_voms,
    max_ntd_id,
    max_primary_uza_population_1,
    max_state_1,
    max_uza_name_1,
    report_year,
    sum_total_hours,
    total_employees,
    total_operating_hours,
    total_salaries,
    dt,
    execution_ts
FROM stg_ntd__employees_by_agency
