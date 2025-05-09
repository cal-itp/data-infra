WITH staging_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_directly_generated') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_funding_sources_directly_generated AS (
    SELECT
        stg.agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
        stg.advertising,
        stg.advertising_questionable,
        stg.agency_voms,
        stg.concessions,
        stg.concessions_questionable,
        stg.fares,
        stg.fares_questionable,
        stg.organization_type,
        stg.other,
        stg.other_questionable,
        stg.park_and_ride,
        stg.park_and_ride_questionable,
        stg.primary_uza_population,
        stg.purchased_transportation,
        stg.purchased_transportation_1,
        stg.reporter_type,
        stg.total,
        stg.total_questionable,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_directly_generated AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_funding_sources_directly_generated
