WITH external_monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__monthly_modal_time_series_safety_and_service') }}
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
    SAFE_CAST(major_non_physical_assaults_on_operators AS FLOAT64) AS major_non_physical_assaults_on_operators,
    SAFE_CAST(major_non_physical_assaults_on_other_transit_workers AS FLOAT64) AS major_non_physical_assaults_on_other_transit_workers,
    SAFE_CAST(major_physical_assaults_on_operators AS FLOAT64) AS major_physical_assaults_on_operators,
    SAFE_CAST(non_major_non_physical_assaults_on_other_transit_workers AS FLOAT64) AS non_major_non_physical_assaults_on_other_transit_workers,
    SAFE_CAST(non_major_physical_assaults_on_other_transit_workers AS FLOAT64) AS non_major_physical_assaults_on_other_transit_workers,
    SAFE_CAST(non_major_non_physical_assaults_on_operators AS FLOAT64) AS non_major_non_physical_assaults_on_operators,
    SAFE_CAST(total_injuries AS INTEGER) AS total_injuries,
    SAFE_CAST(trespasser_injuries AS INTEGER) AS trespasser_injuries,
    SAFE_CAST(other_injuries AS INTEGER) AS other_injuries,
    SAFE_CAST(other_vehicle_occupant_1 AS INTEGER) AS other_vehicle_occupant_1,
    SAFE_CAST(pedestrian_walking_along_1 AS INTEGER) AS pedestrian_walking_along_1,
    SAFE_CAST(pedestrian_in_corsswalk AS INTEGER) AS pedestrian_in_corsswalk,
    SAFE_CAST(bicyclist_injuries AS INTEGER) AS bicyclist_injuries,
    SAFE_CAST(other_worker_injuries AS INTEGER) AS other_worker_injuries,
    SAFE_CAST(total_employee_injuries AS INTEGER) AS total_employee_injuries,
    SAFE_CAST(other_employee_injuries AS INTEGER) AS other_employee_injuries,
    SAFE_CAST(operator_injuries AS INTEGER) AS operator_injuries,
    SAFE_CAST(total_other_fatalities AS INTEGER) AS total_other_fatalities,
    SAFE_CAST(other_vehicle_occupant AS INTEGER) AS other_vehicle_occupant,
    SAFE_CAST(people_waiting_or_leaving_1 AS INTEGER) AS people_waiting_or_leaving_1,
    SAFE_CAST(total_fatalities AS INTEGER) AS total_fatalities,
    SAFE_CAST(trespasser_fatalities AS INTEGER) AS trespasser_fatalities,
    SAFE_CAST(suicide_injuries AS INTEGER) AS suicide_injuries,
    SAFE_CAST(collisions_with_other AS INTEGER) AS collisions_with_other,
    SAFE_CAST(pedestrian_walking_along AS INTEGER) AS pedestrian_walking_along,
    SAFE_CAST(suicide_fatalities AS INTEGER) AS suicide_fatalities,
    SAFE_CAST(pedestrian_in_crosswalk AS INTEGER) AS pedestrian_in_crosswalk,
    SAFE_CAST(bicyclist_fatalities AS INTEGER) AS bicyclist_fatalities,
    SAFE_CAST(other_worker_fatalities AS INTEGER) AS other_worker_fatalities,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    SAFE_CAST(passenger_fatalities AS INTEGER) AS passenger_fatalities,
    SAFE_CAST(total_employee_fatalities AS INTEGER) AS total_employee_fatalities,
    SAFE_CAST(operator_fatalities AS INTEGER) AS operator_fatalities,
    SAFE_CAST(people_waiting_or_leaving AS INTEGER) AS people_waiting_or_leaving,
    SAFE_CAST(uace_code AS NUMERIC) AS uace_code,
    {{ trim_make_empty_string_null('month') }} AS month,
    SAFE_CAST(total_events_not_otherwise AS INTEGER) AS total_events_not_otherwise,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(collisions_with_bus_vehicle AS INTEGER) AS collisions_with_bus_vehicle,
    SAFE_CAST(total_security_events AS INTEGER) AS total_security_events,
    SAFE_CAST(total_events AS INTEGER) AS total_events,
    SAFE_CAST(rail_y_n AS BOOLEAN) AS rail_y_n,
    SAFE_CAST(total_fires AS INTEGER) AS total_fires,
    SAFE_CAST(total_derailments AS INTEGER) AS total_derailments,
    SAFE_CAST(pedestrian_crossing_tracks AS INTEGER) AS pedestrian_crossing_tracks,
    SAFE_CAST(total_assaults_on_transit_workers AS FLOAT64) AS total_assaults_on_transit_workers,
    SAFE_CAST(total_collisions AS INTEGER) AS total_collisions,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(collisions_with_rail_vehicle AS INTEGER) AS collisions_with_rail_vehicle,
    SAFE_CAST(passenger_injuries AS INTEGER) AS passenger_injuries,
    SAFE_CAST(collisions_with_fixed_object AS INTEGER) AS collisions_with_fixed_object,
    SAFE_CAST(ridership AS NUMERIC) AS ridership,
    SAFE_CAST(service_area_population AS NUMERIC) AS service_area_population,
    SAFE_CAST(collisions_with_person AS INTEGER) AS collisions_with_person,
    SAFE_CAST(major_physical_assaults_on_other_transit_workers AS FLOAT64) AS major_physical_assaults_on_other_transit_workers,
    SAFE_CAST(collisions_with_motor_vehicle AS INTEGER) AS collisions_with_motor_vehicle,
    SAFE_CAST(service_area_sq_miles AS NUMERIC) AS service_area_sq_miles,
    SAFE_CAST(other_employee_fatalities AS INTEGER) AS other_employee_fatalities,
    SAFE_CAST(non_major_physical_assaults_on_operators AS FLOAT64) AS non_major_physical_assaults_on_operators,
    SAFE_CAST(year AS INTEGER) AS year,
    SAFE_CAST(vehicle_revenue_hours AS NUMERIC) AS vehicle_revenue_hours,
    SAFE_CAST(pedestrian_not_in_crosswalk_1 AS INTEGER) AS pedestrian_not_in_crosswalk_1,
    SAFE_CAST(vehicle_revenue_miles AS NUMERIC) AS vehicle_revenue_miles,
    SAFE_CAST(vehicles AS NUMERIC) AS vehicles,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(pedestrian_crossing_tracks_1 AS INTEGER) AS pedestrian_crossing_tracks_1,
    SAFE_CAST(primary_uza_sq_miles AS NUMERIC) AS primary_uza_sq_miles,
    {{ trim_make_empty_string_null('primary_uza_name') }} AS primary_uza_name,
    SAFE_CAST(_5_digit_ntd_id AS INTEGER) AS _5_digit_ntd_id,
    SAFE_CAST(total_other_injuries AS INTEGER) AS total_other_injuries,
    SAFE_CAST(other_fatalities AS INTEGER) AS other_fatalities,
    SAFE_CAST(pedestrian_not_in_crosswalk AS INTEGER) AS pedestrian_not_in_crosswalk,
    dt,
    execution_ts
FROM stg_ntd__monthly_modal_time_series_safety_and_service
