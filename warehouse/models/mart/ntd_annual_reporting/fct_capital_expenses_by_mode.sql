WITH staging_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_mode') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('33c3d376e7d93b04c210041d62e015f2','1bebb98cd526881d0beab080dafd1e6a','1d5f79c7f06b68f023dd6513f8d797d4',
        'f8b280fb1301a54725feefa098f519ec','9078bab61ab02779f9a4a5b043e377d9','1e9138bb433fed360f111c90866fc94a',
        'e1503c0491fb6666f060aa64276fb707','faf75088d148925ea862051b49b54429')
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

fct_capital_expenses_by_mode AS (
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
        stg.count_administrative_buildings_q,
        stg.count_communication_information_q,
        stg.count_fare_collection_equipment_q,
        stg.count_maintenance_buildings_q,
        stg.count_other_q,
        stg.count_other_vehicles_q,
        stg.count_passenger_vehicles_q,
        stg.count_reduced_reporter_q,
        stg.count_stations_q,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_administrative_buildings,
        stg.sum_communication_information,
        stg.sum_fare_collection_equipment,
        stg.sum_guideway,
        stg.sum_maintenance_buildings,
        stg.sum_other,
        stg.sum_other_vehicles,
        stg.sum_passenger_vehicles,
        stg.sum_reduced_reporter,
        stg.sum_stations,
        stg.sum_total,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_by_mode AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_capital_expenses_by_mode
