WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_funding_sources_federal AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.city,
        stg.fta_capital_program_5309,
        stg.fta_rural_progam_5311,
        stg.fta_urbanized_area_formula,
        stg.ntd_id,
        stg.organization_type,
        stg.other_dot_funds,
        stg.other_federal_funds,
        stg.other_fta_funds,
        stg.primary_uza_population,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.total_federal_funds,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_federal AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_funding_sources_federal
