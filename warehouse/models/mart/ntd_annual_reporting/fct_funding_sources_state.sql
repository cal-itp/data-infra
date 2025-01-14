WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_state') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_funding_sources_state AS (
    SELECT
        staging_funding_sources_state.*,
        dim_organizations.caltrans_district
    FROM staging_funding_sources_state
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_funding_sources_state.report_year = 2022 THEN
                staging_funding_sources_state.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_funding_sources_state.ntd_id = dim_organizations.ntd_id
        END
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
