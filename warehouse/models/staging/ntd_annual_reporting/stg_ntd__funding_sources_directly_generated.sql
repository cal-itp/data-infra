WITH external_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_directly_generated') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_directly_generated
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_directly_generated AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    advertising,
    advertising_questionable,
    agency,
    agency_voms,
    city,
    concessions,
    concessions_questionable,
    fares,
    fares_questionable,
    ntd_id,
    organization_type,
    other,
    other_questionable,
    park_and_ride,
    park_and_ride_questionable,
    primary_uza_population,
    purchased_transportation,
    purchased_transportation_1,
    report_year,
    reporter_type,
    state,
    total,
    total_questionable,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_directly_generated
