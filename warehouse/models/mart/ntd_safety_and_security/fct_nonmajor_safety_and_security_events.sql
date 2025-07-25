WITH staging_nonmajor_safety_and_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__nonmajor_safety_and_security_events') }}
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

fct_nonmajor_safety_and_security_events AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.incident_number,
        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg.uace_code,
        stg.fixed_route_flag,
        stg.incident_description,
        stg.incident_date,
        stg.incident_time,
        stg.event_type,
        stg.event_type_group,
        stg.event_category,
        stg.safety_security,
        stg.collision_with,
        stg.property_damage,
        stg.property_damage_type,
        stg.location_type,
        stg.multiple_locations_list,
        stg.latitude,
        stg.longitude,
        stg.latlon,
        stg.approximate_address,
        stg.total_injuries,
        stg.total_fatalities,
        stg.number_of_transit_vehicles,
        stg.number_of_vehicles_involved,
        stg.number_of_cars_on_involved_transit_vehicles,
        stg.derailed_cars_count,
        stg.other_vehicle_type_list,
        stg.evacuation,
        stg.evac_to_right_of_way,
        stg.evacuation_comment,
        stg.evacuation_location,
        stg.towed_y_n,
        stg.life_safety_y_n,
        stg.self_evacuation_y_n,
        stg.intentional_y_n,
        stg.transit_y_n,
        stg.hazmat_type,
        stg.hazmat_type_description,
        stg.fire_type,
        stg.fire_fuel,
        stg.other_fire_fuel_description,
        stg.weather,
        stg.weather_comment,
        stg.lighting,
        stg.current_condition,
        stg.tide,
        stg.road_configuration,
        stg.track_configuration,
        stg.path_condition,
        stg.rail_alignment,
        stg.rail_grade_crossing_control,
        stg.rail_grade_crossing_comment,
        stg.rail_bus_ferry,
        stg.runaway_train_flag,
        stg.right_of_way_condition,
        stg.intersection,
        stg.service_stop_control_device,
        stg.operator_location,
        stg.vehicle_action,
        stg.action_type,
        stg.derailment_type,
        stg.fuel_type,
        stg.vehicle_speed,
        stg.non_rail_transit_vehicle,
        stg.non_transit_vehicle_action_list,
        stg.manufacturer,
        stg.manufacturer_description,
        stg.assault_homicide_person_type_desc,
        stg.assault_homicide_type_desc,
        stg.assault_homicide_transit_worker_flag,
        stg.other_event_type_description,
        stg.bicyclist_fatalities,
        stg.bicyclist_injuries,
        stg.bicyclist_serious_injuries,
        stg.occupant_of_other_vehicle,
        stg.occupant_of_other_vehicle_1,
        stg.occupant_of_other_vehicle_2,
        stg.pedestrian_in_crosswalk,
        stg.pederstiran_in_crosswalk,
        stg.pederstiran_in_crosswalk_1,
        stg.pedestrian_not_in_crosswalk,
        stg.pedestrian_not_in_crosswalk_1,
        stg.pedestrian_not_in_crosswalk_2,
        stg.pedestrian_crossing_tracks,
        stg.pedestrian_crossing_tracks_1,
        stg.pedestrian_crossing_tracks_2,
        stg.pedestrian_walking_along,
        stg.pedestrian_walking_along_1,
        stg.pedestrian_walking_along_2,
        stg.people_waiting_or_leaving,
        stg.people_waiting_or_leaving_1,
        stg.people_waiting_or_leaving_2,
        stg.suicide_fatalities,
        stg.suicide_injuries,
        stg.suicide_serious_injuries,
        stg.transit_employee_fatalities,
        stg.transit_employee_injuries,
        stg.transit_employee_serious,
        stg.transit_vehicle_type,
        stg.transit_vehicle_operator,
        stg.transit_vehicle_operator_1,
        stg.transit_vehicle_operator_2,
        stg.transit_vehicle_rider,
        stg.transit_vehicle_rider_injuries,
        stg.transit_vehicle_rider_serious,
        stg.trespasser_fatalities_subtotal_,
        stg.trespasser_inuries_subtotal_,
        stg.trespasser_serious_injuries_subtotal_,
        stg.other_fatalities,
        stg.other_injuries,
        stg.other_serious_injuries,
        stg.other_worker_fatalities,
        stg.other_worker_injuries,
        stg.other_worker_serious_injuries,
        stg.total_serious_injuries,
        stg.person_list,
        stg.revenue_vehicle_identifier_list,
        stg.agency AS source_agency,
        stg.dt,
        stg.execution_ts
    FROM staging_nonmajor_safety_and_security_events AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.year = agency.year
)

SELECT * FROM fct_nonmajor_safety_and_security_events
