WITH external_monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'multi_year__monthly_modal_time_series_safety_and_service') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_monthly_modal_time_series_safety_and_service
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    major_non_physical_assaults_on_operators,
    major_non_physical_assaults_on_other_transit_workers,
    major_physical_assaults_on_operators,
    non_major_non_physical_assaults_on_other_transit_workers,
    non_major_physical_assaults_on_other_transit_workers,
    non_major_non_physical_assaults_on_operators,
    total_injuries,
    trespasser_injuries,
    other_injuries,
    other_vehicle_occupant_1,
    pedestrian_walking_along_1,
    pedestrian_in_corsswalk,
    bicyclist_injuries,
    other_worker_injuries,
    total_employee_injuries,
    other_employee_injuries,
    operator_injuries,
    total_other_fatalities,
    other_vehicle_occupant,
    people_waiting_or_leaving_1,
    total_fatalities,
    trespasser_fatalities,
    suicide_injuries,
    collisions_with_other,
    pedestrian_walking_along,
    suicide_fatalities,
    pedestrian_in_crosswalk,
    bicyclist_fatalities,
    other_worker_fatalities,
    type_of_service,
    mode,
    passenger_fatalities,
    total_employee_fatalities,
    operator_fatalities,
    people_waiting_or_leaving,
    uace_code,
    month,
    total_events_not_otherwise,
    primary_uza_population,
    collisions_with_bus_vehicle,
    total_security_events,
    total_events,
    rail_y_n,
    total_fires,
    total_derailments,
    pedestrian_crossing_tracks,
    total_assaults_on_transit_workers,
    total_collisions,
    agency,
    collisions_with_rail_vehicle,
    passenger_injuries,
    collisions_with_fixed_object,
    ridership,
    service_area_population,
    collisions_with_person,
    major_physical_assaults_on_other_transit_workers,
    collisions_with_motor_vehicle,
    service_area_sq_miles,
    other_employee_fatalities,
    non_major_physical_assaults_on_operators,
    year,
    vehicle_revenue_hours,
    pedestrian_not_in_crosswalk_1,
    vehicle_revenue_miles,
    vehicles,
    organization_type,
    pedestrian_crossing_tracks_1,
    primary_uza_sq_miles,
    primary_uza_name,
    _5_digit_ntd_id,
    total_other_injuries,
    other_fatalities,
    pedestrian_not_in_crosswalk,
    dt,
    execution_ts
FROM stg_ntd__monthly_modal_time_series_safety_and_service
