WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_state') }}
),

fct_funding_sources_state AS (
    SELECT *
    FROM staging_funding_sources_state
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
    dt,
    execution_ts
FROM fct_funding_sources_state
