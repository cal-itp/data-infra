WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
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

fct_funding_sources_by_expense_type AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.fund_expenditure_type,
        stg.agency_voms,
        stg.fares_and_other_directly,
        stg.fares_and_other_directly_1,
        stg.federal,
        stg.federal_questionable,
        stg.local,
        stg.local_questionable,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.state_questionable,
        stg.taxes_fees_levied_by_transit,
        stg.taxes_fees_levied_by_transit_1,
        stg.total,
        stg.state_1,
        stg.total_questionable,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_by_expense_type AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('6a1794e7bf7c786ac7c6278c48d18532','065cc04d5e8091177b9931485040fd47','1eef6b1521f4cf58b40a21e35ebf45a2',
        'baaa3db5d4afc13f0ee55c683f42bf62','7d61960d93bb36b8059a70ed728d90c9','cd664c7a5a7ff6387859cc3bd35f116d',
        '1b0cb4f9c03f630cfc28cbb1e7b3f2e7','f009e9f0645cf14a1e4a4edc1137a5e2')
)

SELECT * FROM fct_funding_sources_by_expense_type
