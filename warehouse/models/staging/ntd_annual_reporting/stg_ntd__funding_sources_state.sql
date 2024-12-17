WITH external_funding_sources_state AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_state') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_state
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_state AS (
    SELECT *
    FROM get_latest_extract
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
FROM stg_ntd__funding_sources_state
