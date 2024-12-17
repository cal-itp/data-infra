WITH external_funding_sources_local AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_local') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_local
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_local AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('agency_voms') }} AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST({{ trim_make_empty_string_null('fuel_tax') }} AS NUMERIC) AS fuel_tax,
    SAFE_CAST({{ trim_make_empty_string_null('general_fund') }} AS NUMERIC) AS general_fund,
    SAFE_CAST({{ trim_make_empty_string_null('income_tax') }} AS NUMERIC) AS income_tax,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST({{ trim_make_empty_string_null('other_funds') }} AS NUMERIC) AS other_funds,
    SAFE_CAST({{ trim_make_empty_string_null('other_taxes') }} AS NUMERIC) AS other_taxes,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_population') }} AS NUMERIC) AS primary_uza_population,
    SAFE_CAST({{ trim_make_empty_string_null('property_tax') }} AS NUMERIC) AS property_tax,
    SAFE_CAST({{ trim_make_empty_string_null('reduced_reporter_funds') }} AS NUMERIC) AS reduced_reporter_funds,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    SAFE_CAST({{ trim_make_empty_string_null('sales_tax') }} AS NUMERIC) AS sales_tax,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST({{ trim_make_empty_string_null('tolls') }} AS NUMERIC) AS tolls,
    SAFE_CAST({{ trim_make_empty_string_null('total') }} AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_local
