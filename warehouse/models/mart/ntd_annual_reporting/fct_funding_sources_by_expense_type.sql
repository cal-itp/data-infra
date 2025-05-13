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
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.fund_expenditure_type']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.agency_voms,
        stg.fares_and_other_directly,
        stg.fares_and_other_directly_1,
        stg.federal,
        stg.federal_questionable,
        stg.fund_expenditure_type,
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
)

SELECT * FROM fct_funding_sources_by_expense_type
