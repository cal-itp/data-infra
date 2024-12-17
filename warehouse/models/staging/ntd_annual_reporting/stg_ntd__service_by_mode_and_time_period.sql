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
    {{ trim_make_empty_string_null('_5_digit_ntd_id') }} AS _5_digit_ntd_id,
    SAFE_CAST(actual_vehicles_passenger_car_deadhead_hours AS NUMERIC) AS actual_vehicles_passenger_car_deadhead_hours,
    SAFE_CAST(actual_vehicles_passenger_car_hours AS NUMERIC) AS actual_vehicles_passenger_car_hours,
    SAFE_CAST(actual_vehicles_passenger_car_miles AS NUMERIC) AS actual_vehicles_passenger_car_miles,
    SAFE_CAST(actual_vehicles_passenger_car_revenue_hours AS NUMERIC) AS actual_vehicles_passenger_car_revenue_hours,
    SAFE_CAST(actual_vehicles_passenger_car_revenue_miles AS NUMERIC) AS actual_vehicles_passenger_car_revenue_miles,
    SAFE_CAST(actual_vehicles_passenger_deadhead_miles AS NUMERIC) AS actual_vehicles_passenger_deadhead_miles,
    SAFE_CAST(ada_upt AS NUMERIC) AS ada_upt,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('aptl_questionable') }} AS aptl_questionable,
    SAFE_CAST(average_passenger_trip_length_aptl_ AS NUMERIC) AS average_passenger_trip_length_aptl_,
    SAFE_CAST(average_speed AS NUMERIC) AS average_speed,
    {{ trim_make_empty_string_null('average_speed_questionable') }} AS average_speed_questionable,
    SAFE_CAST(brt_non_statutory_mixed_traffic AS NUMERIC) AS brt_non_statutory_mixed_traffic,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(charter_service_hours AS NUMERIC) AS charter_service_hours,
    SAFE_CAST(days_of_service_operated AS NUMERIC) AS days_of_service_operated,
    SAFE_CAST(days_not_operated_strikes AS NUMERIC) AS days_not_operated_strikes,
    SAFE_CAST(days_not_operated_emergencies AS NUMERIC) AS days_not_operated_emergencies,
    {{ trim_make_empty_string_null('deadhead_hours_questionable') }} AS deadhead_hours_questionable,
    {{ trim_make_empty_string_null('deadhead_miles_questionable') }} AS deadhead_miles_questionable,
    SAFE_CAST(directional_route_miles AS NUMERIC) AS directional_route_miles,
    {{ trim_make_empty_string_null('directional_route_miles_questionable') }} AS directional_route_miles_questionable,
    SAFE_CAST(mixed_traffic_right_of_way AS NUMERIC) AS mixed_traffic_right_of_way,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('mode_voms_questionable') }} AS mode_voms_questionable,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(passenger_miles AS NUMERIC) AS passenger_miles,
    {{ trim_make_empty_string_null('passenger_miles_questionable') }} AS passenger_miles_questionable,
    SAFE_CAST(passengers_per_hour AS NUMERIC) AS passengers_per_hour,
    {{ trim_make_empty_string_null('passengers_per_hour_questionable') }} AS passengers_per_hour_questionable,
    SAFE_CAST(primary_uza_area_sq_miles AS NUMERIC) AS primary_uza_area_sq_miles,
    SAFE_CAST(primary_uza_code AS NUMERIC) AS primary_uza_code,
    {{ trim_make_empty_string_null('primary_uza_name') }} AS primary_uza_name,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('scheduled_revenue_miles_questionable') }} AS scheduled_revenue_miles_questionable,
    SAFE_CAST(scheduled_vehicles_passenger_car_revenue_miles AS NUMERIC) AS scheduled_vehicles_passenger_car_revenue_miles,
    SAFE_CAST(school_bus_hours AS NUMERIC) AS school_bus_hours,
    SAFE_CAST(service_area_population AS NUMERIC) AS service_area_population,
    SAFE_CAST(service_area_sq_miles AS NUMERIC) AS service_area_sq_miles,
    SAFE_CAST(sponsored_service_upt AS NUMERIC) AS sponsored_service_upt,
    {{ trim_make_empty_string_null('state') }} AS state,
    {{ trim_make_empty_string_null('time_period') }} AS time_period,
    {{ trim_make_empty_string_null('time_service_begins') }} AS time_service_begins,
    {{ trim_make_empty_string_null('time_service_ends') }} AS time_service_ends,
    SAFE_CAST(train_deadhead_hours AS NUMERIC) AS train_deadhead_hours,
    SAFE_CAST(train_deadhead_miles AS NUMERIC) AS train_deadhead_miles,
    SAFE_CAST(train_hours AS NUMERIC) AS train_hours,
    {{ trim_make_empty_string_null('train_hours_questionable') }} AS train_hours_questionable,
    SAFE_CAST(trains_in_operation AS NUMERIC) AS trains_in_operation,
    {{ trim_make_empty_string_null('trains_in_operation_questionable') }} AS trains_in_operation_questionable,
    SAFE_CAST(train_miles AS NUMERIC) AS train_miles,
    {{ trim_make_empty_string_null('train_miles_questionable') }} AS train_miles_questionable,
    SAFE_CAST(train_revenue_hours AS NUMERIC) AS train_revenue_hours,
    {{ trim_make_empty_string_null('train_revenue_hours_questionable') }} AS train_revenue_hours_questionable,
    SAFE_CAST(train_revenue_miles AS NUMERIC) AS train_revenue_miles,
    {{ trim_make_empty_string_null('train_revenue_miles_questionable') }} AS train_revenue_miles_questionable,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    SAFE_CAST(unlinked_passenger_trips_upt AS NUMERIC) AS unlinked_passenger_trips_upt,
    {{ trim_make_empty_string_null('unlinked_passenger_trips_questionable') }} AS unlinked_passenger_trips_questionable,
    {{ trim_make_empty_string_null('vehicle_hours_questionable') }} AS vehicle_hours_questionable,
    {{ trim_make_empty_string_null('vehicle_miles_questionable') }} AS vehicle_miles_questionable,
    {{ trim_make_empty_string_null('vehicle_revenue_hours_questionable') }} AS vehicle_revenue_hours_questionable,
    {{ trim_make_empty_string_null('vehicle_revenue_miles_questionable') }} AS vehicle_revenue_miles_questionable,
    dt,
    execution_ts
FROM stg_ntd__service_by_mode_and_time_period
