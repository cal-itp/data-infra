WITH staging_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_taxes_levied_by_agency') }}
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

fct_funding_sources_taxes_levied_by_agency AS (
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
        stg.fuel_tax,
        stg.income_tax,
        stg.organization_type,
        stg.other_funds,
        stg.other_tax,
        stg.primary_uza_population,
        stg.property_tax,
        stg.reporter_type,
        stg.sales_tax,
        stg.tolls,
        stg.total,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_funding_sources_taxes_levied_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_funding_sources_taxes_levied_by_agency
