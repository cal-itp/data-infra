WITH staging_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_directly_generated') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('0610e7c75b67e0edd77f3ef3117b15ba','abd981f1eeb176cd71024b38c0ce24e6','ef4dab4a487ec44305b459568f3fb3f6',
        '9d4f1caeda82b63dcee955f1009b34d6')
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_funding_sources_directly_generated AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

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
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_directly_generated AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_funding_sources_directly_generated
