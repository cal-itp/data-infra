WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
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

fct_funding_sources_federal AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.agency_voms,
        stg.fta_capital_program_5309,
        stg.fta_rural_progam_5311,
        stg.fta_urbanized_area_formula,
        stg.organization_type,
        stg.other_dot_funds,
        stg.other_federal_funds,
        stg.other_fta_funds,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_federal_funds,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_federal AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('abd981f1eeb176cd71024b38c0ce24e6','0610e7c75b67e0edd77f3ef3117b15ba','ef4dab4a487ec44305b459568f3fb3f6',
        '9d4f1caeda82b63dcee955f1009b34d6')
)

SELECT * FROM fct_funding_sources_federal
