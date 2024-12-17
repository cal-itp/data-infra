WITH external_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__service_by_mode_and_time_period') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_service_by_mode_and_time_period
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__service_by_mode_and_time_period AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    _5_digit_ntd_id,
    actual_vehicles_passenger_car_deadhead_hours,
    actual_vehicles_passenger_car_hours,
    actual_vehicles_passenger_car_miles,
    actual_vehicles_passenger_car_revenue_hours,
    actual_vehicles_passenger_car_revenue_miles,
    actual_vehicles_passenger_deadhead_miles,
    ada_upt,
    agency,
    agency_voms,
    aptl_questionable,
    average_passenger_trip_length_aptl_,
    average_speed,
    average_speed_questionable,
    brt_non_statutory_mixed_traffic,
    city,
    charter_service_hours,
    days_of_service_operated,
    days_not_operated_strikes,
    days_not_operated_emergencies,
    deadhead_hours_questionable,
    deadhead_miles_questionable,
    directional_route_miles,
    directional_route_miles_questionable,
    mixed_traffic_right_of_way,
    mode,
    mode_name,
    mode_voms,
    mode_voms_questionable,
    organization_type,
    passenger_miles,
    passenger_miles_questionable,
    passengers_per_hour,
    passengers_per_hour_questionable,
    primary_uza_area_sq_miles,
    primary_uza_code,
    primary_uza_name,
    primary_uza_population,
    report_year,
    reporter_type,
    scheduled_revenue_miles_questionable,
    scheduled_vehicles_passenger_car_revenue_miles,
    school_bus_hours,
    service_area_population,
    service_area_sq_miles,
    sponsored_service_upt,
    state,
    time_period,
    time_service_begins,
    time_service_ends,
    train_deadhead_hours,
    train_deadhead_miles,
    train_hours,
    train_hours_questionable,
    trains_in_operation,
    trains_in_operation_questionable,
    train_miles,
    train_miles_questionable,
    train_revenue_hours,
    train_revenue_hours_questionable,
    train_revenue_miles,
    train_revenue_miles_questionable,
    type_of_service,
    unlinked_passenger_trips_upt,
    unlinked_passenger_trips_questionable,
    vehicle_hours_questionable,
    vehicle_miles_questionable,
    vehicle_revenue_hours_questionable,
    vehicle_revenue_miles_questionable,
    dt,
    execution_ts
FROM stg_ntd__service_by_mode_and_time_period
