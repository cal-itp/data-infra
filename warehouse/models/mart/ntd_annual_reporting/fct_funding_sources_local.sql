WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_funding_sources_local AS (
    SELECT
        staging_funding_sources_local.*,
        dim_organizations.caltrans_district
    FROM staging_funding_sources_local
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_funding_sources_local.report_year = 2022 THEN
                staging_funding_sources_local.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_funding_sources_local.ntd_id = dim_organizations.ntd_id
        END
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
