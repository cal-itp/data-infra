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
    SELECT
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(facility_maintenance AS NUMERIC) AS facility_maintenance,
        {{ trim_make_empty_string_null('facility_maintenance_1') }} AS facility_maintenance_1,
        SAFE_CAST(general_administration AS NUMERIC) AS general_administration,
        {{ trim_make_empty_string_null('general_administration_1') }} AS general_administration_1,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
        SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(reduced_reporter_expenses AS NUMERIC) AS reduced_reporter_expenses,
        {{ trim_make_empty_string_null('reduced_reporter_expenses_1') }} AS reduced_reporter_expenses_1,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        SAFE_CAST(separate_report_amount AS NUMERIC) AS separate_report_amount,
        {{ trim_make_empty_string_null('separate_report_amount_1') }} AS separate_report_amount_1,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total AS NUMERIC) AS total,
        {{ trim_make_empty_string_null('total_questionable') }} AS total_questionable,
        {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
        SAFE_CAST(vehicle_maintenance AS NUMERIC) AS vehicle_maintenance,
        {{ trim_make_empty_string_null('vehicle_maintenance_1') }} AS vehicle_maintenance_1,
        SAFE_CAST(vehicle_operations AS NUMERIC) AS vehicle_operations,
        {{ trim_make_empty_string_null('vehicle_operations_1') }} AS vehicle_operations_1,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__operating_expenses_by_function
