WITH external_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__fra_regulated_mode_major_security_events') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_fra_regulated_mode_major_security_events
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('other_vehicle_action') }} AS other_vehicle_action,
    {{ trim_make_empty_string_null('manufacturer_description') }} AS manufacturer_description,
    {{ trim_make_empty_string_null('evacuation_comment') }} AS evacuation_comment,
    {{ trim_make_empty_string_null('manufacturer') }} AS manufacturer,
    {{ trim_make_empty_string_null('non_rail_transit_vehicle') }} AS non_rail_transit_vehicle,
    {{ trim_make_empty_string_null('fuel_type') }} AS fuel_type,
    {{ trim_make_empty_string_null('transit_y_n') }} AS transit_y_n,
    {{ trim_make_empty_string_null('evacuation_location') }} AS evacuation_location,
    {{ trim_make_empty_string_null('rail_alignment') }} AS rail_alignment,
    {{ trim_make_empty_string_null('path_condition') }} AS path_condition,
    {{ trim_make_empty_string_null('weather') }} AS weather,
    {{ trim_make_empty_string_null('collision_with') }} AS collision_with,
    {{ trim_make_empty_string_null('fire_type') }} AS fire_type,
    SAFE_CAST(suicide_serious_injuries AS INTEGER) AS suicide_serious_injuries,
    SAFE_CAST(other_serious_injuries AS INTEGER) AS other_serious_injuries,
    SAFE_CAST(other_injuries AS INTEGER) AS other_injuries,
    SAFE_CAST(occupant_of_other_vehicle_2 AS INTEGER) AS occupant_of_other_vehicle_2,
    {{ trim_make_empty_string_null('other_involved_veh') }} AS other_involved_veh,
    SAFE_CAST(vehicle_speed AS NUMERIC) AS vehicle_speed,
    SAFE_CAST(occupant_of_other_vehicle_1 AS INTEGER) AS occupant_of_other_vehicle_1,
    SAFE_CAST(pedestrian_walking_along_1 AS INTEGER) AS pedestrian_walking_along_1,
    {{ trim_make_empty_string_null('vehicle_action') }} AS vehicle_action,
    SAFE_CAST(pedestrian_crossing_tracks_1 AS INTEGER) AS pedestrian_crossing_tracks_1,
    SAFE_CAST(pedestrian_not_in_crosswalk_1 AS INTEGER) AS pedestrian_not_in_crosswalk_1,
    SAFE_CAST(pedestrian_in_crosswalk_2 AS INTEGER) AS pedestrian_in_crosswalk_2,
    SAFE_CAST(pedestrian_in_crosswalk_1 AS INTEGER) AS pedestrian_in_crosswalk_1,
    {{ trim_make_empty_string_null('rail_bus_ferry') }} AS rail_bus_ferry,
    SAFE_CAST(people_waiting_or_leaving AS INTEGER) AS people_waiting_or_leaving,
    SAFE_CAST(other_worker_serious_injuries AS INTEGER) AS other_worker_serious_injuries,
    SAFE_CAST(transit_employee_injuries AS INTEGER) AS transit_employee_injuries,
    {{ trim_make_empty_string_null('configuration') }} AS configuration,
    SAFE_CAST(transit_vehicle_rider_serious AS INTEGER) AS transit_vehicle_rider_serious,
    SAFE_CAST(longitude AS NUMERIC) AS longitude,
    SAFE_CAST(occupant_of_other_vehicle AS INTEGER) AS occupant_of_other_vehicle,
    SAFE_CAST(pedestrian_crossing_tracks AS INTEGER) AS pedestrian_crossing_tracks,
    SAFE_CAST(latitude AS NUMERIC) AS latitude,
    {{ trim_make_empty_string_null('lighting') }} AS lighting,
    SAFE_CAST(people_waiting_or_leaving_2 AS INTEGER) AS people_waiting_or_leaving_2,
    SAFE_CAST(other_worker_injuries AS INTEGER) AS other_worker_injuries,
    SAFE_CAST(transit_vehicle_rider_injuries AS INTEGER) AS transit_vehicle_rider_injuries,
    SAFE_CAST(suicide_fatalities AS INTEGER) AS suicide_fatalities,
    SAFE_CAST(transit_vehicle_rider AS INTEGER) AS transit_vehicle_rider,
    SAFE_CAST(pedestrian_in_crosswalk AS INTEGER) AS pedestrian_in_crosswalk,
    {{ trim_make_empty_string_null('action_type') }} AS action_type,
    SAFE_CAST(bicyclist_serious_injuries AS INTEGER) AS bicyclist_serious_injuries,
    SAFE_CAST(total_fatalities AS INTEGER) AS total_fatalities,
    SAFE_CAST(people_waiting_or_leaving_1 AS INTEGER) AS people_waiting_or_leaving_1,
    SAFE_CAST(pedestrian_crossing_tracks_2 AS INTEGER) AS pedestrian_crossing_tracks_2,
    SAFE_CAST(bicyclist_fatalities AS INTEGER) AS bicyclist_fatalities,
    {{ trim_make_empty_string_null('safety_security') }} AS safety_security,
    SAFE_CAST(transit_employee_fatalities AS INTEGER) AS transit_employee_fatalities,
    SAFE_CAST(transit_vehicle_operator AS INTEGER) AS transit_vehicle_operator,
    {{ trim_make_empty_string_null('property_damage_type') }} AS property_damage_type,
    SAFE_CAST(transit_employee_serious AS INTEGER) AS transit_employee_serious,
    {{ trim_make_empty_string_null('rail_grade_crossing_control') }} AS rail_grade_crossing_control,
    SAFE_CAST(intentional_y_n AS NUMERIC) AS intentional_y_n,
    SAFE_CAST(total_injuries AS INTEGER) AS total_injuries,
    {{ trim_make_empty_string_null('event_type') }} AS event_type,
    {{ trim_make_empty_string_null('event_location') }} AS event_location,
    SAFE_CAST(number_of_vehicles_involved AS INTEGER) AS number_of_vehicles_involved,
    SAFE_CAST(suicide_injuries AS INTEGER) AS suicide_injuries,
    SAFE_CAST(pedestrian_walking_along AS INTEGER) AS pedestrian_walking_along,
    {{ trim_make_empty_string_null('person_list') }} AS person_list,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    SAFE_CAST(self_evacuation_y_n AS BOOLEAN) AS self_evacuation_y_n,
    SAFE_CAST(bicyclist_injuries AS INTEGER) AS bicyclist_injuries,
    SAFE_CAST(property_damage AS NUMERIC) AS property_damage,
    SAFE_CAST(pedestrian_not_in_crosswalk_2 AS INTEGER) AS pedestrian_not_in_crosswalk_2,
    SAFE_CAST(fixed_route_flag AS BOOLEAN) AS fixed_route_flag,
    SAFE_CAST(transit_vehicle_operator_1 AS INTEGER) AS transit_vehicle_operator_1,
    {{ trim_make_empty_string_null('incident_description') }} AS incident_description,
    incident_date,
    {{ trim_make_empty_string_null('approximate_address') }} AS approximate_address,
    SAFE_CAST(other_worker_fatalities AS INTEGER) AS other_worker_fatalities,
    SAFE_CAST(incident_time AS INTEGER) AS incident_time,
    SAFE_CAST(pedestrian_walking_along_2 AS INTEGER) AS pedestrian_walking_along_2,
    SAFE_CAST(towed_y_n AS BOOLEAN) AS towed_y_n,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    {{ trim_make_empty_string_null('right_of_way_condition') }} AS right_of_way_condition,
    {{ trim_make_empty_string_null('fire_fuel') }} AS fire_fuel,
    SAFE_CAST(number_of_transit_vehicles AS INTEGER) AS number_of_transit_vehicles,
    SAFE_CAST(year AS INTEGER) AS year,
    SAFE_CAST(transit_vehicle_operator_2 AS INTEGER) AS transit_vehicle_operator_2,
    SAFE_CAST(incident_number AS INTEGER) AS incident_number,
    SAFE_CAST(other_fatalities AS INTEGER) AS other_fatalities,
    SAFE_CAST(pedestrian_not_in_crosswalk AS INTEGER) AS pedestrian_not_in_crosswalk,
    SAFE_CAST(number_of_derailed_cars AS NUMERIC) AS number_of_derailed_cars,
    SAFE_CAST(ntd_id AS INTEGER) AS ntd_id,
    dt,
    execution_ts
FROM stg_ntd__fra_regulated_mode_major_security_events