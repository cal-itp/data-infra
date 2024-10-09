{{ config(materialized="table") }}

WITH source AS (
    SELECT * FROM {{ ref("stg_ntd_annual_data__2022__service_by_agency") }}
)

SELECT {{ dbt_utils.generate_surrogate_key(['report_year', '_5_digit_ntd_id']) }} as key,
       report_year,
       _5_digit_ntd_id AS ntd_id,
       agency,
       max_reporter_type,
       max_organization_type,
       max_city,
       max_state,
       max_agency_voms,
       max_primary_uza_code,
       max_primary_uza_name,
       max_primary_uza_area_sq_miles,
       max_primary_uza_population,
       max_service_area_sq_miles,
       max_service_area_population,
       sum_actual_vehicles_passenger_car_deadhead_hours,
       sum_actual_vehicles_passenger_car_hours,
       sum_actual_vehicles_passenger_car_miles,
       sum_actual_vehicles_passenger_car_revenue_hours,
       sum_actual_vehicles_passenger_car_revenue_miles,
       sum_actual_vehicles_passenger_deadhead_miles,
       sum_scheduled_vehicles_passenger_car_revenue_miles,
       sum_charter_service_hours,
       sum_school_bus_hours,
       sum_trains_in_operation,
       sum_directional_route_miles,
       sum_passenger_miles,
       sum_train_miles,
       sum_train_revenue_miles,
       sum_train_deadhead_miles,
       sum_train_hours,
       sum_train_revenue_hours,
       sum_train_deadhead_hours,
       sum_ada_upt,
       sum_sponsored_service_upt,
       sum_unlinked_passenger_trips_upt
  FROM source
