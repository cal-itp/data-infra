WITH staging_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_taxes_levied_by_agency') }}
),

fct_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM staging_funding_sources_taxes_levied_by_agency
)

SELECT
    agency,
    agency_voms,
    city,
    fuel_tax,
    income_tax,
    ntd_id,
    organization_type,
    other_funds,
    other_tax,
    primary_uza_population,
    property_tax,
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
FROM fct_funding_sources_taxes_levied_by_agency
