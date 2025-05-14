WITH staging_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_mode_and_time_period') }}
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

fct_service_by_mode_and_time_period AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.mode', 'stg.type_of_service', 'stg.time_period']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.actual_vehicles_passenger_car_deadhead_hours,
        stg.actual_vehicles_passenger_car_hours,
        stg.actual_vehicles_passenger_car_miles,
        stg.actual_vehicles_passenger_car_revenue_hours,
        stg.actual_vehicles_passenger_car_revenue_miles,
        stg.actual_vehicles_passenger_deadhead_miles,
        stg.ada_upt,
        stg.agency_voms,
        stg.aptl_questionable,
        stg.average_passenger_trip_length_aptl_,
        stg.average_speed,
        stg.average_speed_questionable,
        stg.brt_non_statutory_mixed_traffic,
        stg.charter_service_hours,
        stg.days_of_service_operated,
        stg.days_not_operated_strikes,
        stg.days_not_operated_emergencies,
        stg.deadhead_hours_questionable,
        stg.deadhead_miles_questionable,
        stg.directional_route_miles,
        stg.directional_route_miles_questionable,
        stg.mixed_traffic_right_of_way,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.mode_voms_questionable,
        stg.organization_type,
        stg.passenger_miles,
        stg.passenger_miles_questionable,
        stg.passengers_per_hour,
        stg.passengers_per_hour_questionable,
        stg.primary_uza_area_sq_miles,
        stg.primary_uza_code,
        stg.primary_uza_name,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.scheduled_revenue_miles_questionable,
        stg.scheduled_vehicles_passenger_car_revenue_miles,
        stg.school_bus_hours,
        stg.service_area_population,
        stg.service_area_sq_miles,
        stg.sponsored_service_upt,
        stg.time_period,
        stg.time_service_begins,
        stg.time_service_ends,
        stg.train_deadhead_hours,
        stg.train_deadhead_miles,
        stg.train_hours,
        stg.train_hours_questionable,
        stg.trains_in_operation,
        stg.trains_in_operation_questionable,
        stg.train_miles,
        stg.train_miles_questionable,
        stg.train_revenue_hours,
        stg.train_revenue_hours_questionable,
        stg.train_revenue_miles,
        stg.train_revenue_miles_questionable,
        stg.type_of_service,
        stg.unlinked_passenger_trips_upt,
        stg.unlinked_passenger_trips_questionable,
        stg.vehicle_hours_questionable,
        stg.vehicle_miles_questionable,
        stg.vehicle_revenue_hours_questionable,
        stg.vehicle_revenue_miles_questionable,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_service_by_mode_and_time_period AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_service_by_mode_and_time_period
