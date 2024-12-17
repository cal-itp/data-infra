WITH external_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_by_expense_type') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_by_expense_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_by_expense_type AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(fares_and_other_directly AS NUMERIC) AS fares_and_other_directly,
    {{ trim_make_empty_string_null('fares_and_other_directly_1') }} AS fares_and_other_directly_1,
    SAFE_CAST(federal AS NUMERIC) AS federal,
    {{ trim_make_empty_string_null('federal_questionable') }} AS federal_questionable,
    {{ trim_make_empty_string_null('fund_expenditure_type') }} AS fund_expenditure_type,
    SAFE_CAST(local AS NUMERIC) AS local,
    {{ trim_make_empty_string_null('local_questionable') }} AS local_questionable,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(state_1 AS NUMERIC) AS state_1,
    {{ trim_make_empty_string_null('state_questionable') }} AS state_questionable,
    SAFE_CAST(taxes_fees_levied_by_transit AS NUMERIC) AS taxes_fees_levied_by_transit,
    {{ trim_make_empty_string_null('taxes_fees_levied_by_transit_1') }} AS taxes_fees_levied_by_transit_1,
    SAFE_CAST(total AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('total_questionable') }} AS total_questionable,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_by_expense_type
