WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_funding_sources_local AS (
    SELECT
        stg.agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
        stg.agency_voms,
        stg.fuel_tax,
        stg.general_fund,
        stg.income_tax,
        stg.organization_type,
        stg.other_funds,
        stg.other_taxes,
        stg.primary_uza_population,
        stg.property_tax,
        stg.reduced_reporter_funds,
        stg.reporter_type,
        stg.sales_tax,
        stg.tolls,
        stg.total,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_local AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_funding_sources_local
