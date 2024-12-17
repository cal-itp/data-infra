WITH external_employees_by_mode AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__employees_by_mode') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_employees_by_mode
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__employees_by_mode AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(count_capital_labor_count_q AS NUMERIC) AS count_capital_labor_count_q,
    SAFE_CAST(count_capital_labor_hours_q AS NUMERIC) AS count_capital_labor_hours_q,
    SAFE_CAST(count_facility_maintenance_count_q AS NUMERIC) AS count_facility_maintenance_count_q,
    SAFE_CAST(count_facility_maintenance_hours_q AS NUMERIC) AS count_facility_maintenance_hours_q,
    SAFE_CAST(count_general_administration_count_q AS NUMERIC) AS count_general_administration_count_q,
    SAFE_CAST(count_general_administration_hours_q AS NUMERIC) AS count_general_administration_hours_q,
    SAFE_CAST(count_total_employee_count_q AS NUMERIC) AS count_total_employee_count_q,
    SAFE_CAST(count_total_employee_hours_q AS NUMERIC) AS count_total_employee_hours_q,
    SAFE_CAST(count_vehicle_maintenance_count_q AS NUMERIC) AS count_vehicle_maintenance_count_q,
    SAFE_CAST(count_vehicle_maintenance_hours_q AS NUMERIC) AS count_vehicle_maintenance_hours_q,
    SAFE_CAST(count_vehicle_operations_count_q AS NUMERIC) AS count_vehicle_operations_count_q,
    SAFE_CAST(count_vehicle_operations_hours_q AS NUMERIC) AS count_vehicle_operations_hours_q,
    {{ trim_make_empty_string_null('max_mode_name') }} AS max_mode_name,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST(sum_total_employee_count AS NUMERIC) AS sum_total_employee_count,
    SAFE_CAST(sum_total_hours AS NUMERIC) AS sum_total_hours,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    dt,
    execution_ts
FROM stg_ntd__employees_by_mode
