WITH external_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_by_expense_type') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_by_expense_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_by_expense_type AS (
    SELECT *
    FROM get_latest_extract
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
FROM stg_ntd__funding_sources_by_expense_type
