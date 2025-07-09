WITH external_funding_sources_federal AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_federal') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_federal
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_federal AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year']) }} AS key,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(fta_capital_program_5309 AS NUMERIC) AS fta_capital_program_5309,
        SAFE_CAST(fta_rural_progam_5311 AS NUMERIC) AS fta_rural_progam_5311,
        SAFE_CAST(fta_urbanized_area_formula AS NUMERIC) AS fta_urbanized_area_formula,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(other_dot_funds AS NUMERIC) AS other_dot_funds,
        SAFE_CAST(other_federal_funds AS NUMERIC) AS other_federal_funds,
        SAFE_CAST(other_fta_funds AS NUMERIC) AS other_fta_funds,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total_federal_funds AS NUMERIC) AS total_federal_funds,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__funding_sources_federal
