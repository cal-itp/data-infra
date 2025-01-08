WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
),

fct_funding_sources_by_expense_type AS (
    SELECT *
    FROM staging_funding_sources_by_expense_type
)

SELECT
    agency,
    agency_voms,
    city,
    fares_and_other_directly,
    fares_and_other_directly_1,
    federal,
    federal_questionable,
    fund_expenditure_type,
    local,
    local_questionable,
    ntd_id,
    organization_type,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    state_1,
    state_questionable,
    taxes_fees_levied_by_transit,
    taxes_fees_levied_by_transit_1,
    total,
    total_questionable,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM fct_funding_sources_by_expense_type
