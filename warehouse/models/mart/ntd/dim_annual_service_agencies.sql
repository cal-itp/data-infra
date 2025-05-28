{{ config(materialized="table") }}

WITH source AS (
    SELECT * FROM {{ ref("stg_ntd__service_by_agency") }}
)

SELECT {{ dbt_utils.generate_surrogate_key(['report_year', 'ntd_id']) }} as key,
       report_year,
       ntd_id,
       agency,
       max_reporter_type AS reporter_type,
       max_organization_type AS organization_type,
       max_city AS city,
       max_state AS state,
       max_agency_voms AS agency_voms,
       max_primary_uza_code AS primary_uza_code,
       max_primary_uza_name AS primary_uza_name,
       max_primary_uza_area_sq_miles AS primary_uza_area_sq_miles,
       max_primary_uza_population AS primary_uza_population,
       max_service_area_sq_miles AS service_area_sq_miles,
       max_service_area_population AS service_area_population,
       sum_actual_vehicles_passenger_car_deadhead_hours AS actual_vehicles_passenger_car_deadhead_hours,
       sum_actual_vehicles_passenger_car_hours AS actual_vehicles_passenger_car_hours,
       sum_actual_vehicles_passenger_car_miles AS actual_vehicles_passenger_car_miles,
       sum_actual_vehicles_passenger_car_revenue_hours AS actual_vehicles_passenger_car_revenue_hours,
       sum_actual_vehicles_passenger_car_revenue_miles AS actual_vehicles_passenger_car_revenue_miles,
       sum_actual_vehicles_passenger_deadhead_miles AS actual_vehicles_passenger_deadhead_miles,
       sum_scheduled_vehicles_passenger_car_revenue_miles AS scheduled_vehicles_passenger_car_revenue_miles,
       sum_charter_service_hours AS charter_service_hours,
       sum_school_bus_hours AS school_bus_hours,
       sum_trains_in_operation AS trains_in_operation,
       sum_directional_route_miles AS directional_route_miles,
       sum_passenger_miles AS passenger_miles,
       sum_train_miles AS train_miles,
       sum_train_revenue_miles AS train_revenue_miles,
       sum_train_deadhead_miles AS train_deadhead_miles,
       sum_train_hours AS train_hours,
       sum_train_revenue_hours AS train_revenue_hours,
       sum_train_deadhead_hours AS train_deadhead_hours,
       sum_ada_upt AS ada_upt,
       sum_sponsored_service_upt AS sponsored_service_upt,
       sum_unlinked_passenger_trips_upt AS unlinked_passenger_trips_upt
  FROM source
