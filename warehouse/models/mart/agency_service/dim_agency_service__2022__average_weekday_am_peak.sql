{{ config(materialized='table') }}

WITH service_by_mode_and_time_period__2022 AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__2022__service_by_mode_and_time_period') }}
),

dim_agency_service__2022__average_weekday_am_peak as (
    SELECT

        _5_digit_ntd_id,
        actual_vehicles_passenger_car_deadhead_hours,
        actual_vehicles_passenger_car_hours,
        actual_vehicles_passenger_car_miles,
        actual_vehicles_passenger_car_revenue_hours,
        actual_vehicles_passenger_car_revenue_miles,
        actual_vehicles_passenger_deadhead_miles,
        agency,
        agency_voms,
        average_speed,
        city,
        directional_route_miles,
        mode,
        mode_name,
        mode_voms,
        organization_type,
        passenger_miles,
        passengers_per_hour,
        report_year,
        reporter_type,
        scheduled_vehicles_passenger_car_revenue_miles,
        sponsored_service_upt,
        state,
        time_period,
        train_hours,
        train_miles,
        train_revenue_hours,
        train_revenue_miles,
        trains_in_operation,
        type_of_service,
        unlinked_passenger_trips_upt,
        dt,
        execution_ts

    FROM service_by_mode_and_time_period__2022
    WHERE time_period = 'Average Weekday - AM Peak'

)
SELECT * FROM dim_agency_service__2022__average_weekday_am_peak
