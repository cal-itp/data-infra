WITH external_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_taxes_levied_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_taxes_levied_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(fuel_tax AS NUMERIC) AS fuel_tax,
    SAFE_CAST(income_tax AS NUMERIC) AS income_tax,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(other_funds AS NUMERIC) AS other_funds,
    SAFE_CAST(other_tax AS NUMERIC) AS other_tax,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(property_tax AS NUMERIC) AS property_tax,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    SAFE_CAST(sales_tax AS NUMERIC) AS sales_tax,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(tolls AS NUMERIC) AS tolls,
    SAFE_CAST(total AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_taxes_levied_by_agency
