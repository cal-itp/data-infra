WITH staging_service_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_mode') }}
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

fct_service_by_mode AS (
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
        stg.max_agency_voms,
        stg.max_mode_voms,
        stg.max_organization_type,
        stg.max_primary_uza_area_sq_miles,
        stg.max_primary_uza_code,
        stg.max_primary_uza_name,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_service_area_population,
        stg.max_service_area_sq_miles,
        stg.max_time_period,
        stg.min_time_service_begins,
        stg.max_time_service_ends,
        stg.questionable_record,
        stg.sum_actual_vehicles_passenger_car_deadhead_hours,
        stg.sum_actual_vehicles_passenger_car_hours,
        stg.sum_actual_vehicles_passenger_car_miles,
        stg.sum_actual_vehicles_passenger_car_revenue_hours,
        stg.sum_actual_vehicles_passenger_car_revenue_miles,
        stg.sum_actual_vehicles_passenger_deadhead_miles,
        stg.sum_ada_upt,
        stg.sum_charter_service_hours,
        stg.sum_days_not_operated_emergencies,
        stg.sum_days_not_operated_strikes,
        stg.sum_days_of_service_operated,
        stg.sum_directional_route_miles,
        stg.sum_passenger_miles,
        stg.sum_scheduled_vehicles_passenger_car_revenue_miles,
        stg.sum_school_bus_hours,
        stg.sum_sponsored_service_upt,
        stg.sum_train_deadhead_hours,
        stg.sum_train_deadhead_miles,
        stg.sum_train_hours,
        stg.sum_train_miles,
        stg.sum_train_revenue_hours,
        stg.sum_train_revenue_miles,
        stg.sum_trains_in_operation,
        stg.sum_unlinked_passenger_trips_upt,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_service_by_mode AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('1bebb98cd526881d0beab080dafd1e6a','33c3d376e7d93b04c210041d62e015f2','1d5f79c7f06b68f023dd6513f8d797d4',
        'f8b280fb1301a54725feefa098f519ec','04804150c414bd12329423ebf09442fd','1e9138bb433fed360f111c90866fc94a',
        '9078bab61ab02779f9a4a5b043e377d9','faf75088d148925ea862051b49b54429','e1503c0491fb6666f060aa64276fb707',
        '61eeee88a89ab9a2e63c24ac99d297b8')
)

SELECT * FROM fct_service_by_mode
