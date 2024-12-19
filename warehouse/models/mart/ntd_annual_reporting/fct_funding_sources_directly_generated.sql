WITH staging_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_directly_generated') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_funding_sources_directly_generated AS (
    SELECT
        staging_funding_sources_directly_generated.*,
        dim_organizations.caltrans_district
    FROM staging_funding_sources_directly_generated
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_funding_sources_directly_generated.report_year = 2022 THEN
                staging_funding_sources_directly_generated.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_funding_sources_directly_generated.ntd_id = dim_organizations.ntd_id
        END
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_funding_sources_directly_generated
