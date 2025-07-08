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
        stg.time_period,
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
    -- remove bad rows for 'Advance Transit, Inc. NH', 'Southern Teton Area Rapid Transit', and 'Kalkaska Public Transit Authority'
    WHERE stg.key NOT IN ('8249c3edd6e3ce37e7663591c460d0a9','063e7d113742bab53d8e327b157df33c','61ca12e52b3e7fe6ea22cc9635c6f1a5',
        '99709cd169b23eea637d5a9a9a8a6e32','71eeb5ff8553dfafb8cf6c5dba61fc69','2e24abdb740090bdeea934fdecee7d0f',
        'eaa78d6ef093cceb176d4794c09b4c69','d171c06fce80055e26efdee455f23b91','1782b752dd706696ae543f000c794745',
        '425aa98d3d9add78b5f46dc96f401038','8b1523481382724b8c342c484e64b04f','6ff561acc39510e268c3af39c3a42d07')
)

SELECT * FROM fct_service_by_mode_and_time_period
