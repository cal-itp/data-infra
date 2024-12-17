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
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('avgwagerate') }} AS FLOAT64) AS avgwagerate,
    SAFE_CAST({{ trim_make_empty_string_null('count_capital_labor_count_q') }} AS NUMERIC) AS count_capital_labor_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_capital_labor_hours_q') }} AS NUMERIC) AS count_capital_labor_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_facility_maintenance_count_q') }} AS NUMERIC) AS count_facility_maintenance_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_facility_maintenance_hours_q') }} AS NUMERIC) AS count_facility_maintenance_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_general_administration_count_q') }} AS NUMERIC) AS count_general_administration_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_general_administration_hours_q') }} AS NUMERIC) AS count_general_administration_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_total_employee_count_q') }} AS NUMERIC) AS count_total_employee_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_total_employee_hours_q') }} AS NUMERIC) AS count_total_employee_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_vehicle_maintenance_count_q') }} AS NUMERIC) AS count_vehicle_maintenance_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_vehicle_maintenance_hours_q') }} AS NUMERIC) AS count_vehicle_maintenance_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_vehicle_operations_count_q') }} AS NUMERIC) AS count_vehicle_operations_count_q,
    SAFE_CAST({{ trim_make_empty_string_null('count_vehicle_operations_hours_q') }} AS NUMERIC) AS count_vehicle_operations_hours_q,
    SAFE_CAST({{ trim_make_empty_string_null('max_agency_voms_1') }} AS NUMERIC) AS max_agency_voms_1,
    {{ trim_make_empty_string_null('max_city_1') }} AS max_city_1,
    SAFE_CAST({{ trim_make_empty_string_null('max_mode_voms') }} AS NUMERIC) AS max_mode_voms,
    {{ trim_make_empty_string_null('max_ntd_id') }} AS max_ntd_id,
    SAFE_CAST({{ trim_make_empty_string_null('max_primary_uza_population_1') }} AS NUMERIC) AS max_primary_uza_population_1,
    {{ trim_make_empty_string_null('max_state_1') }} AS max_state_1,
    {{ trim_make_empty_string_null('max_uza_name_1') }} AS max_uza_name_1,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST({{ trim_make_empty_string_null('sum_total_hours') }} AS NUMERIC) AS sum_total_hours,
    SAFE_CAST({{ trim_make_empty_string_null('total_employees') }} AS NUMERIC) AS total_employees,
    SAFE_CAST({{ trim_make_empty_string_null('total_operating_hours') }} AS NUMERIC) AS total_operating_hours,
    SAFE_CAST({{ trim_make_empty_string_null('total_salaries') }} AS NUMERIC) AS total_salaries,
    dt,
    execution_ts
FROM stg_ntd__employees_by_agency
