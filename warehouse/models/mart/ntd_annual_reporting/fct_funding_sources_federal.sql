WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
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
        staging_funding_sources_federal.*,
        current_dim_organizations.caltrans_district
    FROM staging_funding_sources_federal
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_funding_sources_federal AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_funding_sources_federal
