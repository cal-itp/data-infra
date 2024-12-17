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
    {{ trim_make_empty_string_null('major_non_physical_assaults_on_operators') }} AS major_non_physical_assaults_on_operators,
    {{ trim_make_empty_string_null('major_non_physical_assaults_on_other_transit_workers') }} AS major_non_physical_assaults_on_other_transit_workers,
    {{ trim_make_empty_string_null('major_physical_assaults_on_operators') }} AS major_physical_assaults_on_operators,
    {{ trim_make_empty_string_null('non_major_non_physical_assaults_on_other_transit_workers') }} AS non_major_non_physical_assaults_on_other_transit_workers,
    {{ trim_make_empty_string_null('non_major_physical_assaults_on_other_transit_workers') }} AS non_major_physical_assaults_on_other_transit_workers,
    {{ trim_make_empty_string_null('non_major_non_physical_assaults_on_operators') }} AS non_major_non_physical_assaults_on_operators,
    SAFE_CAST({{ trim_make_empty_string_null('total_injuries') }} AS INTEGER) AS total_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('trespasser_injuries') }} AS INTEGER) AS trespasser_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('other_injuries') }} AS INTEGER) AS other_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('other_vehicle_occupant_1') }} AS INTEGER) AS other_vehicle_occupant_1,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_walking_along_1') }} AS INTEGER) AS pedestrian_walking_along_1,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_in_corsswalk') }} AS INTEGER) AS pedestrian_in_corsswalk,
    SAFE_CAST({{ trim_make_empty_string_null('bicyclist_injuries') }} AS INTEGER) AS bicyclist_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('other_worker_injuries') }} AS INTEGER) AS other_worker_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('total_employee_injuries') }} AS INTEGER) AS total_employee_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('other_employee_injuries') }} AS INTEGER) AS other_employee_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('operator_injuries') }} AS INTEGER) AS operator_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('total_other_fatalities') }} AS INTEGER) AS total_other_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('other_vehicle_occupant') }} AS INTEGER) AS other_vehicle_occupant,
    SAFE_CAST({{ trim_make_empty_string_null('people_waiting_or_leaving_1') }} AS INTEGER) AS people_waiting_or_leaving_1,
    SAFE_CAST({{ trim_make_empty_string_null('total_fatalities') }} AS INTEGER) AS total_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('trespasser_fatalities') }} AS INTEGER) AS trespasser_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('suicide_injuries') }} AS INTEGER) AS suicide_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_other') }} AS INTEGER) AS collisions_with_other,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_walking_along') }} AS INTEGER) AS pedestrian_walking_along,
    SAFE_CAST({{ trim_make_empty_string_null('suicide_fatalities') }} AS INTEGER) AS suicide_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_in_crosswalk') }} AS INTEGER) AS pedestrian_in_crosswalk,
    SAFE_CAST({{ trim_make_empty_string_null('bicyclist_fatalities') }} AS INTEGER) AS bicyclist_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('other_worker_fatalities') }} AS INTEGER) AS other_worker_fatalities,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    SAFE_CAST({{ trim_make_empty_string_null('passenger_fatalities') }} AS INTEGER) AS passenger_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('total_employee_fatalities') }} AS INTEGER) AS total_employee_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('operator_fatalities') }} AS INTEGER) AS operator_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('people_waiting_or_leaving') }} AS INTEGER) AS people_waiting_or_leaving,
    SAFE_CAST({{ trim_make_empty_string_null('uace_code') }} AS FLOAT) AS uace_code,
    {{ trim_make_empty_string_null('month') }} AS month,
    SAFE_CAST({{ trim_make_empty_string_null('total_events_not_otherwise') }} AS INTEGER) AS total_events_not_otherwise,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_population') }} AS FLOAT) AS primary_uza_population,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_bus_vehicle') }} AS INTEGER) AS collisions_with_bus_vehicle,
    SAFE_CAST({{ trim_make_empty_string_null('total_security_events') }} AS INTEGER) AS total_security_events,
    SAFE_CAST({{ trim_make_empty_string_null('total_events') }} AS INTEGER) AS total_events,
    SAFE_CAST({{ trim_make_empty_string_null('rail_y_n') }} AS BOOLEAN) AS rail_y_n,
    SAFE_CAST({{ trim_make_empty_string_null('total_fires') }} AS INTEGER) AS total_fires,
    SAFE_CAST({{ trim_make_empty_string_null('total_derailments') }} AS INTEGER) AS total_derailments,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_crossing_tracks') }} AS INTEGER) AS pedestrian_crossing_tracks,
    {{ trim_make_empty_string_null('total_assaults_on_transit_workers') }} AS total_assaults_on_transit_workers,
    SAFE_CAST({{ trim_make_empty_string_null('total_collisions') }} AS INTEGER) AS total_collisions,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_rail_vehicle') }} AS INTEGER) AS collisions_with_rail_vehicle,
    SAFE_CAST({{ trim_make_empty_string_null('passenger_injuries') }} AS INTEGER) AS passenger_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_fixed_object') }} AS INTEGER) AS collisions_with_fixed_object,
    SAFE_CAST({{ trim_make_empty_string_null('ridership') }} AS FLOAT) AS ridership,
    SAFE_CAST({{ trim_make_empty_string_null('service_area_population') }} AS FLOAT) AS service_area_population,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_person') }} AS INTEGER) AS collisions_with_person,
    {{ trim_make_empty_string_null('major_physical_assaults_on_other_transit_workers') }} AS major_physical_assaults_on_other_transit_workers,
    SAFE_CAST({{ trim_make_empty_string_null('collisions_with_motor_vehicle') }} AS INTEGER) AS collisions_with_motor_vehicle,
    SAFE_CAST({{ trim_make_empty_string_null('service_area_sq_miles') }} AS FLOAT) AS service_area_sq_miles,
    SAFE_CAST({{ trim_make_empty_string_null('other_employee_fatalities') }} AS INTEGER) AS other_employee_fatalities,
    {{ trim_make_empty_string_null('non_major_physical_assaults_on_operators') }} AS non_major_physical_assaults_on_operators,
    SAFE_CAST({{ trim_make_empty_string_null('year') }} AS INTEGER) AS year,
    SAFE_CAST({{ trim_make_empty_string_null('vehicle_revenue_hours') }} AS FLOAT) AS vehicle_revenue_hours,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_not_in_crosswalk_1') }} AS INTEGER) AS pedestrian_not_in_crosswalk_1,
    SAFE_CAST({{ trim_make_empty_string_null('vehicle_revenue_miles') }} AS FLOAT) AS vehicle_revenue_miles,
    SAFE_CAST({{ trim_make_empty_string_null('vehicles') }} AS FLOAT) AS vehicles,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_crossing_tracks_1') }} AS INTEGER) AS pedestrian_crossing_tracks_1,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_sq_miles') }} AS FLOAT) AS primary_uza_sq_miles,
    {{ trim_make_empty_string_null('primary_uza_name') }} AS primary_uza_name,
    SAFE_CAST({{ trim_make_empty_string_null('_5_digit_ntd_id') }} AS INTEGER) AS _5_digit_ntd_id,
    SAFE_CAST({{ trim_make_empty_string_null('total_other_injuries') }} AS INTEGER) AS total_other_injuries,
    SAFE_CAST({{ trim_make_empty_string_null('other_fatalities') }} AS INTEGER) AS other_fatalities,
    SAFE_CAST({{ trim_make_empty_string_null('pedestrian_not_in_crosswalk') }} AS INTEGER) AS pedestrian_not_in_crosswalk,
    dt,
    execution_ts
FROM stg_ntd__monthly_modal_time_series_safety_and_service
