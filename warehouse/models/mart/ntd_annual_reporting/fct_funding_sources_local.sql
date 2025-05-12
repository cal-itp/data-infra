WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_funding_sources_local AS (
    SELECT
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

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
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_local AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_funding_sources_local
