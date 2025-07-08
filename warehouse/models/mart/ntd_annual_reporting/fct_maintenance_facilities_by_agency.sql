WITH staging_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities_by_agency') }}
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

fct_maintenance_facilities_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_200_to_300_vehicles,
        stg.sum_heavy_maintenance_facilities,
        stg.sum_leased_by_pt_provider,
        stg.sum_leased_by_public_agency,
        stg.sum_leased_from_a_private_entity,
        stg.sum_leased_from_a_public_entity,
        stg.sum_over_300_vehicles,
        stg.sum_owned,
        stg.sum_owned_by_pt_provider,
        stg.sum_owned_by_public_agency,
        stg.sum_total_facilities,
        stg.sum_under_200_vehicles,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_maintenance_facilities_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('abd981f1eeb176cd71024b38c0ce24e6','0610e7c75b67e0edd77f3ef3117b15ba','9d4f1caeda82b63dcee955f1009b34d6',
        'ef4dab4a487ec44305b459568f3fb3f6')
)

SELECT * FROM fct_maintenance_facilities_by_agency
