WITH staging_operating_expenses_by_function_and_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function_and_agency') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('abd981f1eeb176cd71024b38c0ce24e6','0610e7c75b67e0edd77f3ef3117b15ba','9d4f1caeda82b63dcee955f1009b34d6',
        'ef4dab4a487ec44305b459568f3fb3f6')
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

fct_operating_expenses_by_function_and_agency AS (
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
        stg.sum_facility_maintenance,
        stg.sum_general_administration,
        stg.sum_reduced_reporter_expenses,
        stg.sum_separate_report_amount,
        stg.sum_vehicle_maintenance,
        stg.sum_vehicle_operations,
        stg.total,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_function_and_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_operating_expenses_by_function_and_agency
