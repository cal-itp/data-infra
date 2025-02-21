WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_funding_sources_local.*,
        current_dim_organizations.caltrans_district
    FROM staging_funding_sources_local
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_funding_sources_local AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_funding_sources_local
