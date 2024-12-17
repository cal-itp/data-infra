WITH staging_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_directly_generated') }}
),

fct_funding_sources_directly_generated AS (
    SELECT *
    FROM staging_funding_sources_directly_generated
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
FROM fct_funding_sources_directly_generated
