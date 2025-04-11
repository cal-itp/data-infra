WITH fct_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__fra_regulated_mode_major_security_events') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_fra_regulated_mode_major_security_events.*,
        current_dim_organizations.caltrans_district
    FROM staging_fra_regulated_mode_major_security_events
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    other_vehicle_action,
    manufacturer_description,
    evacuation_comment,
    manufacturer,
    non_rail_transit_vehicle,
    fuel_type,
    transit_y_n,
    evacuation_location,
    rail_alignment,
    path_condition,
    weather,
    collision_with,
    fire_type,
    suicide_serious_injuries,
    other_serious_injuries,
    other_injuries,
    occupant_of_other_vehicle_2,
    other_involved_veh,
    vehicle_speed,
    occupant_of_other_vehicle_1,
    pedestrian_walking_along_1,
    vehicle_action,
    pedestrian_crossing_tracks_1,
    pedestrian_not_in_crosswalk_1,
    pedestrian_in_crosswalk_2,
    pedestrian_in_crosswalk_1,
    rail_bus_ferry,
    people_waiting_or_leaving,
    other_worker_serious_injuries,
    transit_employee_injuries,
    configuration,
    transit_vehicle_rider_serious,
    longitude,
    occupant_of_other_vehicle,
    pedestrian_crossing_tracks,
    latitude,
    lighting,
    people_waiting_or_leaving_2,
    other_worker_injuries,
    transit_vehicle_rider_injuries,
    suicide_fatalities,
    transit_vehicle_rider,
    pedestrian_in_crosswalk,
    action_type,
    bicyclist_serious_injuries,
    total_fatalities,
    people_waiting_or_leaving_1,
    pedestrian_crossing_tracks_2,
    bicyclist_fatalities,
    safety_security,
    transit_employee_fatalities,
    transit_vehicle_operator,
    property_damage_type,
    transit_employee_serious,
    rail_grade_crossing_control,
    intentional_y_n,
    total_injuries,
    event_type,
    event_location,
    number_of_vehicles_involved,
    suicide_injuries,
    pedestrian_walking_along,
    person_list,
    type_of_service,
    mode,
    self_evacuation_y_n,
    bicyclist_injuries,
    property_damage,
    pedestrian_not_in_crosswalk_2,
    fixed_route_flag,
    transit_vehicle_operator_1,
    incident_description,
    incident_date,
    approximate_address,
    other_worker_fatalities,
    incident_time,
    pedestrian_walking_along_2,
    towed_y_n,
    agency,
    right_of_way_condition,
    fire_fuel,
    number_of_transit_vehicles,
    year,
    transit_vehicle_operator_2,
    incident_number,
    other_fatalities,
    pedestrian_not_in_crosswalk,
    number_of_derailed_cars,
    ntd_id,
    caltrans_district,
    dt,
    execution_ts
FROM fct_fra_regulated_mode_major_security_events
