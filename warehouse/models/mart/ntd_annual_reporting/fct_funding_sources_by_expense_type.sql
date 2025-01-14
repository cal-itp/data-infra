WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_funding_sources_by_expense_type AS (
    SELECT
        staging_funding_sources_by_expense_type.*,
        dim_organizations.caltrans_district
    FROM staging_funding_sources_by_expense_type
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_funding_sources_by_expense_type.report_year = 2022 THEN
                staging_funding_sources_by_expense_type.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_funding_sources_by_expense_type.ntd_id = dim_organizations.ntd_id
        END
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
