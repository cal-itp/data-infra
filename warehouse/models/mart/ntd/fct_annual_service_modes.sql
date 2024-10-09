{{ config(materialized="table") }}

WITH source AS (
    SELECT * FROM {{ ref("stg_ntd_annual_data__2022__service_by_mode") }}
)

SELECT report_year,
       _5_digit_ntd_id AS ntd_id,
       type_of_service
       mode,
       max_mode_name AS mode_name,
       questionable_record,
       max_agency,
       max_agency_voms,
       max_city,
       max_state,
       max_mode_voms,
       max_organization_type,
       max_primary_uza_area_sq_miles,
       max_primary_uza_code,
       max_primary_uza_name,
       max_primary_uza_population,
       max_reporter_type,
       max_service_area_population,
       max_service_area_sq_miles,
       max_time_period,
       min_time_service_begins,
       max_time_service_ends,
       sum_actual_vehicles_passenger_car_deadhead_hours,
       sum_actual_vehicles_passenger_car_hours,
       sum_actual_vehicles_passenger_car_miles,
       sum_actual_vehicles_passenger_car_revenue_hours,
       sum_actual_vehicles_passenger_car_revenue_miles,
       sum_actual_vehicles_passenger_deadhead_miles,
       sum_ada_upt,
       sum_charter_service_hours,
       sum_days_not_operated_emergencies,
       sum_days_not_operated_strikes,
       sum_days_of_service_operated,
       sum_directional_route_miles,
       sum_passenger_miles,
       sum_scheduled_vehicles_passenger_car_revenue_miles,
       sum_school_bus_hours,
       sum_sponsored_service_upt,
       sum_train_deadhead_hours,
       sum_train_deadhead_miles,
       sum_train_hours,
       sum_train_miles,
       sum_train_revenue_hours,
       sum_train_revenue_miles,
       sum_trains_in_operation,
       sum_unlinked_passenger_trips_upt,
  FROM source
 WHERE source.time_period != "Annual Total"
--WHERE lower(source.time_period) != "annual total" ??

-- Annual Total
-- Average Weekday - AM Peak
-- Average Weekday - Midday
-- Average Weekday - PM Peak
-- Average Weekday - Other
-- Average Typical Weekday
-- Average Typical Saturday
-- Average Typical Sunday
-- null
