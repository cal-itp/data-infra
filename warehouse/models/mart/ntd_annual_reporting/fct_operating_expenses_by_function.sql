WITH staging_operating_expenses_by_function AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_expenses_by_function') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('33c3d376e7d93b04c210041d62e015f2','1bebb98cd526881d0beab080dafd1e6a','f8b280fb1301a54725feefa098f519ec',
        '1d5f79c7f06b68f023dd6513f8d797d4','e1503c0491fb6666f060aa64276fb707','1e9138bb433fed360f111c90866fc94a',
        '04804150c414bd12329423ebf09442fd','9078bab61ab02779f9a4a5b043e377d9','faf75088d148925ea862051b49b54429',
        '61eeee88a89ab9a2e63c24ac99d297b8')
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

fct_operating_expenses_by_function AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg.agency_voms,
        stg.facility_maintenance,
        stg.facility_maintenance_1,
        stg.general_administration,
        stg.general_administration_1,
        stg.mode_voms,
        stg.organization_type,
        stg.primary_uza_population,
        stg.reduced_reporter_expenses,
        stg.reduced_reporter_expenses_1,
        stg.reporter_type,
        stg.separate_report_amount,
        stg.separate_report_amount_1,
        stg.total,
        stg.total_questionable,
        stg.vehicle_maintenance,
        stg.vehicle_maintenance_1,
        stg.vehicle_operations,
        stg.vehicle_operations_1,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_operating_expenses_by_function AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_operating_expenses_by_function
