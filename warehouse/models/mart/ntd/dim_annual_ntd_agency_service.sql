{{ config(materialized="table") }}
with source as (
        select * from {{ ref("stg_ntd__annual_database_service") }}
    ),
ntd_modes as (
    select * from {{ ref("int_ntd__modes") }}
),

dim_annual_ntd_agency_service as (
    SELECT
        _dt,
        year,
        state_parent_ntd_id,
        ntd_id,
        agency_name,
        reporter_type,
        subrecipient_type,
        reporting_module,
        mode,
        n.ntd_mode_full_name as mode_full_name,
        tos,
        time_period,
        time_service_begins,
        time_service_ends,
        vehicles_passenger_cars_operated_in_maximum_service,
        vehicles_passenger_cars_available_for_maximum_service,
        trains_in_operation,
        vehicles_passenger_cars_in_operation,
        actual_vehicles_passenger_car_miles,
        actual_vehicles_passenger_car_revenue_miles,
        actual_vehicle_passenger_deadhead_miles,
        scheduled_actual_vehicle_passenger_car_revenue_miles,
        actual_vehicle_passenger_car_hours,
        actual_vehicle_passenger_car_revenue_hours,
        actual_vehicle_passenger_car_deadhead_hours,
        charter_service_hours,
        school_bus_hours,
        train_miles,
        train_revenue_miles,
        train_deadhead_miles,
        train_hours,
        train_revenue_hours,
        train_deadhead_hours,
        unlinked_passenger_trips__upt_,
        ada_upt,
        sponsored_service_upt,
        passenger_miles,
        days_of_service_operated,
        days_not_operated_due_to_strikes,
        strike_comment,
        days_not_operated_due_to_emergencies,
        emergency_comment,
        non_statutory_mixed_traffic,
        drm_mixed_traffic_row,
    FROM source s
    LEFT JOIN ntd_modes n
    ON
    s.mode = n.ntd_mode_abbreviation
)
SELECT * FROM dim_annual_ntd_agency_service
