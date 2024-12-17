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
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    agency_voms,
    city,
    fta_capital_program_5309,
    fta_rural_progam_5311,
    fta_urbanized_area_formula,
    ntd_id,
    organization_type,
    other_dot_funds,
    other_federal_funds,
    other_fta_funds,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_federal_funds,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_federal
