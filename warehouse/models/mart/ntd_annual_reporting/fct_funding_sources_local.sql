WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

fct_funding_sources_local AS (
    SELECT *
    FROM staging_funding_sources_local
)

SELECT
    agency,
    agency_voms,
    city,
    fuel_tax,
    general_fund,
    income_tax,
    ntd_id,
    organization_type,
    other_funds,
    other_taxes,
    primary_uza_population,
    property_tax,
    reduced_reporter_funds,
    report_year,
    reporter_type,
    sales_tax,
    state,
    tolls,
    total,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM fct_funding_sources_local
