WITH staging_metrics AS (
    SELECT *
    FROM {{ ref('stg_ntd__metrics') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('f8b280fb1301a54725feefa098f519ec','1bebb98cd526881d0beab080dafd1e6a','33c3d376e7d93b04c210041d62e015f2',
        '1d5f79c7f06b68f023dd6513f8d797d4','1e9138bb433fed360f111c90866fc94a','61eeee88a89ab9a2e63c24ac99d297b8',
        '9078bab61ab02779f9a4a5b043e377d9','faf75088d148925ea862051b49b54429','e1503c0491fb6666f060aa64276fb707',
        '04804150c414bd12329423ebf09442fd')
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

fct_metrics AS (
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
        stg.cost_per_hour,
        stg.cost_per_hour_questionable,
        stg.cost_per_passenger,
        stg.cost_per_passenger_1,
        stg.cost_per_passenger_mile,
        stg.cost_per_passenger_mile_1,
        stg.fare_revenues_earned,
        stg.fare_revenues_earned_1,
        stg.fare_revenues_per_total,
        stg.fare_revenues_per_total_1,
        stg.fare_revenues_per_unlinked,
        stg.fare_revenues_per_unlinked_1,
        stg.mode_voms,
        stg.organization_type,
        stg.passenger_miles,
        stg.passenger_miles_questionable,
        stg.passengers_per_hour,
        stg.passengers_per_hour_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_operating_expenses,
        stg.total_operating_expenses_1,
        stg.unlinked_passenger_trips,
        stg.unlinked_passenger_trips_1,
        stg.vehicle_revenue_hours,
        stg.vehicle_revenue_hours_1,
        stg.vehicle_revenue_miles,
        stg.vehicle_revenue_miles_1,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_metrics AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_metrics
