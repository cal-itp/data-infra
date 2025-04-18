WITH staging_funding_sources_by_expense_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_by_expense_type') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_funding_sources_by_expense_type AS (
    SELECT
        stg.agency,
        stg.agency_voms,
        stg.city,
        stg.fares_and_other_directly,
        stg.fares_and_other_directly_1,
        stg.federal,
        stg.federal_questionable,
        stg.fund_expenditure_type,
        stg.local,
        stg.local_questionable,
        stg.ntd_id,
        stg.organization_type,
        stg.primary_uza_population,
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.state_1,
        stg.state_questionable,
        stg.taxes_fees_levied_by_transit,
        stg.taxes_fees_levied_by_transit_1,
        stg.total,
        stg.total_questionable,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_by_expense_type AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_funding_sources_by_expense_type
