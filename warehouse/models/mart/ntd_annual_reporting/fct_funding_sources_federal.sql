WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
),

fct_funding_sources_federal AS (
    SELECT *
    FROM staging_funding_sources_federal
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
FROM fct_funding_sources_federal
