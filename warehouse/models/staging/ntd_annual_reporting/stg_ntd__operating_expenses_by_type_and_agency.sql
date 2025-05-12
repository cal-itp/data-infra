WITH external_operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__operating_expenses_by_type_and_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_operating_expenses_by_type_and_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__operating_expenses_by_type_and_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('max_agency') }} AS agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS city,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    SAFE_CAST(report_year AS INT64) AS report_year,
    SAFE_CAST(sum_casualty_and_liability AS NUMERIC) AS sum_casualty_and_liability,
    SAFE_CAST(sum_fringe_benefits AS NUMERIC) AS sum_fringe_benefits,
    SAFE_CAST(sum_fuel_and_lube AS NUMERIC) AS sum_fuel_and_lube,
    SAFE_CAST(sum_miscellaneous AS NUMERIC) AS sum_miscellaneous,
    SAFE_CAST(sum_operator_paid_absences AS NUMERIC) AS sum_operator_paid_absences,
    SAFE_CAST(sum_operators_wages AS NUMERIC) AS sum_operators_wages,
    SAFE_CAST(sum_other_materials_supplies AS NUMERIC) AS sum_other_materials_supplies,
    SAFE_CAST(sum_other_paid_absences AS NUMERIC) AS sum_other_paid_absences,
    SAFE_CAST(sum_other_salaries_wages AS NUMERIC) AS sum_other_salaries_wages,
    SAFE_CAST(sum_purchased_transportation AS NUMERIC) AS sum_purchased_transportation,
    SAFE_CAST(sum_reduced_reporter_expenses AS NUMERIC) AS sum_reduced_reporter_expenses,
    SAFE_CAST(sum_separate_report_amount AS NUMERIC) AS sum_separate_report_amount,
    SAFE_CAST(sum_services AS NUMERIC) AS sum_services,
    SAFE_CAST(sum_taxes AS NUMERIC) AS sum_taxes,
    SAFE_CAST(sum_tires AS NUMERIC) AS sum_tires,
    SAFE_CAST(sum_total AS NUMERIC) AS sum_total,
    SAFE_CAST(sum_utilities AS NUMERIC) AS sum_utilities,
    dt,
    execution_ts
FROM stg_ntd__operating_expenses_by_type_and_agency
