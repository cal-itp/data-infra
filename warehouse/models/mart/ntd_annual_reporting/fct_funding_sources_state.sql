WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_state') }}
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
        staging_funding_sources_state.*,
        current_dim_organizations.caltrans_district
    FROM staging_funding_sources_state
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_funding_sources_state AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    agency_voms,
    city,
    general_funds,
    ntd_id,
    organization_type,
    primary_uza_population,
    reduced_reporter_funds,
    report_year,
    reporter_type,
    state,
    total,
    total_questionable,
    transportation_funds,
    uace_code,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_funding_sources_state
