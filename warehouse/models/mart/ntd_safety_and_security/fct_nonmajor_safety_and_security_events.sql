WITH fct_nonmajor_safety_and_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__nonmajor_safety_and_security_events') }}
)

SELECT
    ntd_id,
    agency,
    uace_code,
    mode,
    mode_name,
    type_of_service,
    year,
    fixed_route_flag,
    incident_description,
    incident_number,
    incident_date,
    incident_time,
    event_type,
    event_type_group,
    event_category,
    safety_security,
    collision_with,
    property_damage,
    property_damage_type,
    location_type,
    multiple_locations_list,
    latitude,
    longitude,
    latlon,
    approximate_address,
    total_injuries,
    total_fatalities,
    number_of_transit_vehicles,
    number_of_vehicles_involved,
    number_of_cars_on_involved_transit_vehicles,
    derailed_cars_count,
    other_vehicle_type_list,
    evacuation,
    evac_to_right_of_way,
    evacuation_comment,
    evacuation_location,
    towed_y_n,
    life_safety_y_n,
    self_evacuation_y_n,
    intentional_y_n,
    transit_y_n,
    hazmat_type,
    hazmat_type_description,
    fire_type,
    fire_fuel,
    other_fire_fuel_description,
    weather,
    weather_comment,
    lighting,
    current_condition,
    tide,
    road_configuration,
    track_configuration,
    path_condition,
    rail_alignment,
    rail_grade_crossing_control,
    rail_grade_crossing_comment,
    rail_bus_ferry,
    runaway_train_flag,
    right_of_way_condition,
    intersection,
    service_stop_control_device,
    operator_location,
    vehicle_action,
    action_type,
    derailment_type,
    fuel_type,
    vehicle_speed,
    non_rail_transit_vehicle,
    non_transit_vehicle_action_list,
    manufacturer,
    manufacturer_description,
    assault_homicide_person_type_desc,
    assault_homicide_type_desc,
    assault_homicide_transit_worker_flag,
    other_event_type_description,
    bicyclist_fatalities,
    bicyclist_injuries,
    bicyclist_serious_injuries,
    occupant_of_other_vehicle,
    occupant_of_other_vehicle_1,
    occupant_of_other_vehicle_2,
    pedestrian_in_crosswalk,
    pederstiran_in_crosswalk,
    pederstiran_in_crosswalk_1,
    pedestrian_not_in_crosswalk,
    pedestrian_not_in_crosswalk_1,
    pedestrian_not_in_crosswalk_2,
    pedestrian_crossing_tracks,
    pedestrian_crossing_tracks_1,
    pedestrian_crossing_tracks_2,
    pedestrian_walking_along,
    pedestrian_walking_along_1,
    pedestrian_walking_along_2,
    people_waiting_or_leaving,
    people_waiting_or_leaving_1,
    people_waiting_or_leaving_2,
    suicide_fatalities,
    suicide_injuries,
    suicide_serious_injuries,
    transit_employee_fatalities,
    transit_employee_injuries,
    transit_employee_serious,
    transit_vehicle_type,
    transit_vehicle_operator,
    transit_vehicle_operator_1,
    transit_vehicle_operator_2,
    transit_vehicle_rider,
    transit_vehicle_rider_injuries,
    transit_vehicle_rider_serious,
    trespasser_fatalities_subtotal_,
    trespasser_inuries_subtotal_,
    trespasser_serious_injuries_subtotal_,
    other_fatalities,
    other_injuries,
    other_serious_injuries,
    other_worker_fatalities,
    other_worker_injuries,
    other_worker_serious_injuries,
    total_serious_injuries,
    person_list,
    revenue_vehicle_identifier_list,
    dt,
    execution_ts
FROM fct_nonmajor_safety_and_security_events
