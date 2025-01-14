WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_funding_sources_federal AS (
    SELECT
        staging_funding_sources_federal.*,
        dim_organizations.caltrans_district
    FROM staging_funding_sources_federal
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_funding_sources_federal.report_year = 2022 THEN
                staging_funding_sources_federal.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_funding_sources_federal.ntd_id = dim_organizations.ntd_id
        END
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
