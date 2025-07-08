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
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year', 'mode', 'type_of_service', 'full_or_part_time']) }} AS key,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        SAFE_CAST(capital_labor_count AS NUMERIC) AS capital_labor_count,
        {{ trim_make_empty_string_null('capital_labor_count_q') }} AS capital_labor_count_q,
        SAFE_CAST(capital_labor_hours AS NUMERIC) AS capital_labor_hours,
        {{ trim_make_empty_string_null('capital_labor_hours_q') }} AS capital_labor_hours_q,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(facility_maintenance_count AS NUMERIC) AS facility_maintenance_count,
        {{ trim_make_empty_string_null('facility_maintenance_count_q') }} AS facility_maintenance_count_q,
        SAFE_CAST(facility_maintenance_hours AS NUMERIC) AS facility_maintenance_hours,
        {{ trim_make_empty_string_null('facility_maintenance_hours_q') }} AS facility_maintenance_hours_q,
        {{ trim_make_empty_string_null('full_or_part_time') }} AS full_or_part_time,
        SAFE_CAST(general_administration_count AS NUMERIC) AS general_administration_count,
        {{ trim_make_empty_string_null('general_administration_count_q') }} AS general_administration_count_q,
        SAFE_CAST(general_administration_hours AS NUMERIC) AS general_administration_hours,
        {{ trim_make_empty_string_null('general_administration_hours_q') }} AS general_administration_hours_q,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
        SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total_employee_count AS NUMERIC) AS total_employee_count,
        {{ trim_make_empty_string_null('total_employee_count_q') }} AS total_employee_count_q,
        SAFE_CAST(total_hours AS NUMERIC) AS total_hours,
        {{ trim_make_empty_string_null('total_hours_q') }} AS total_hours_q,
        {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        SAFE_CAST(vehicle_maintenance_count AS NUMERIC) AS vehicle_maintenance_count,
        {{ trim_make_empty_string_null('vehicle_maintenance_count_q') }} AS vehicle_maintenance_count_q,
        SAFE_CAST(vehicle_maintenance_hours AS NUMERIC) AS vehicle_maintenance_hours,
        {{ trim_make_empty_string_null('vehicle_maintenance_hours_q') }} AS vehicle_maintenance_hours_q,
        SAFE_CAST(vehicle_operations_count AS NUMERIC) AS vehicle_operations_count,
        {{ trim_make_empty_string_null('vehicle_operations_count_q') }} AS vehicle_operations_count_q,
        SAFE_CAST(vehicle_operations_hours AS NUMERIC) AS vehicle_operations_hours,
        {{ trim_make_empty_string_null('vehicle_operations_hours_q') }} AS vehicle_operations_hours_q,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__employees_by_mode_and_employee_type
