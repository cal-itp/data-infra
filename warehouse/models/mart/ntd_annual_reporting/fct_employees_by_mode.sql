WITH staging_employees_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode') }}
),

fct_employees_by_mode AS (
    SELECT *
    FROM staging_employees_by_mode
)

SELECT
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
    max_mode_name,
    mode,
    ntd_id,
    report_year,
    sum_total_employee_count,
    sum_total_hours,
    type_of_service,
    dt,
    execution_ts
FROM fct_employees_by_mode
