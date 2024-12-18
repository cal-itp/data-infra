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
    {{ trim_make_empty_string_null('agency') }} AS agency,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(sum_facility_maintenance AS NUMERIC) AS sum_facility_maintenance,
    SAFE_CAST(sum_general_administration AS NUMERIC) AS sum_general_administration,
    SAFE_CAST(sum_reduced_reporter_expenses AS NUMERIC) AS sum_reduced_reporter_expenses,
    SAFE_CAST(sum_separate_report_amount AS NUMERIC) AS sum_separate_report_amount,
    SAFE_CAST(sum_vehicle_maintenance AS NUMERIC) AS sum_vehicle_maintenance,
    SAFE_CAST(sum_vehicle_operations AS NUMERIC) AS sum_vehicle_operations,
    SAFE_CAST(total AS NUMERIC) AS total,
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_function_and_agency
