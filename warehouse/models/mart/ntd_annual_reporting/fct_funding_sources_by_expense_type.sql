WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
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
        staging_funding_sources_by_expense_type.*,
        current_dim_organizations.caltrans_district
    FROM staging_funding_sources_by_expense_type
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_funding_sources_by_expense_type AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_funding_sources_by_expense_type
