WITH external_operating_expenses_by_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__operating_expenses_by_type') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_operating_expenses_by_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_expenses_by_type AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    SAFE_CAST(casualty_and_liability AS NUMERIC) AS casualty_and_liability,
    {{ trim_make_empty_string_null('casualty_and_liability_1') }} AS casualty_and_liability_1,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(fringe_benefits AS NUMERIC) AS fringe_benefits,
    {{ trim_make_empty_string_null('fringe_benefits_questionable') }} AS fringe_benefits_questionable,
    SAFE_CAST(fuel_and_lube AS NUMERIC) AS fuel_and_lube,
    {{ trim_make_empty_string_null('fuel_and_lube_questionable') }} AS fuel_and_lube_questionable,
    SAFE_CAST(miscellaneous AS NUMERIC) AS miscellaneous,
    {{ trim_make_empty_string_null('miscellaneous_questionable') }} AS miscellaneous_questionable,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    SAFE_CAST(operator_paid_absences AS NUMERIC) AS operator_paid_absences,
    {{ trim_make_empty_string_null('operator_paid_absences_1') }} AS operator_paid_absences_1,
    SAFE_CAST(operators_wages AS NUMERIC) AS operators_wages,
    {{ trim_make_empty_string_null('operators_wages_questionable') }} AS operators_wages_questionable,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(other_materials_supplies AS NUMERIC) AS other_materials_supplies,
    {{ trim_make_empty_string_null('other_materials_supplies_1') }} AS other_materials_supplies_1,
    {{ trim_make_empty_string_null('other_paid_absences') }} AS other_paid_absences,
    {{ trim_make_empty_string_null('other_paid_absences_1') }} AS other_paid_absences_1,
    SAFE_CAST(other_salaries_wages AS NUMERIC) AS other_salaries_wages,
    {{ trim_make_empty_string_null('other_salaries_wages_1') }} AS other_salaries_wages_1,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(purchased_transportation AS NUMERIC) AS purchased_transportation,
    {{ trim_make_empty_string_null('purchased_transportation_1') }} AS purchased_transportation_1,
    SAFE_CAST(reduced_reporter_expenses AS NUMERIC) AS reduced_reporter_expenses,
    {{ trim_make_empty_string_null('reduced_reporter_expenses_1') }} AS reduced_reporter_expenses_1,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    SAFE_CAST(separate_report_amount AS NUMERIC) AS separate_report_amount,
    {{ trim_make_empty_string_null('separate_report_amount_1') }} AS separate_report_amount_1,
    SAFE_CAST(services AS NUMERIC) AS services,
    {{ trim_make_empty_string_null('services_questionable') }} AS services_questionable,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(taxes AS NUMERIC) AS taxes,
    {{ trim_make_empty_string_null('taxes_questionable') }} AS taxes_questionable,
    SAFE_CAST(tires AS NUMERIC) AS tires,
    {{ trim_make_empty_string_null('tires_questionable') }} AS tires_questionable,
    SAFE_CAST(total AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('total_questionable') }} AS total_questionable,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    SAFE_CAST(utilities AS NUMERIC) AS utilities,
    {{ trim_make_empty_string_null('utilities_questionable') }} AS utilities_questionable,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_type
