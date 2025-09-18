WITH external_nonmajor_safety_and_security_events AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__nonmajor_safety_and_security_events') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_nonmajor_safety_and_security_events
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__nonmajor_safety_and_security_events AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntdid', 'yr', 'mo', 'modecd', 'typeofservicecd', 'eventtype', 'location']) }} AS key,
        {{ trim_make_empty_string_null('ntdid') }} AS ntd_id,
        {{ trim_make_empty_string_null('reportername') }} AS reporter_name,
        {{ trim_make_empty_string_null('modecd') }} AS mode_cd,
        {{ trim_make_empty_string_null('typeofservicecd') }} AS type_of_service_cd,
        {{ trim_make_empty_string_null('mo') }} AS month,
        SAFE_CAST(yr AS INTEGER) AS year,
        {{ trim_make_empty_string_null('sftsecfl') }} AS safety_security_flag,
        {{ trim_make_empty_string_null('eventtype') }} AS event_type,
        {{ trim_make_empty_string_null('location') }} AS location,
        {{ trim_make_empty_string_null('location_group') }} AS location_group,
        SAFE_CAST(minor_physical_assaults_on_operators AS INTEGER) AS minor_physical_assaults_on_operators,
        SAFE_CAST(non_physical_assaults_on_operators_security_events_only_ AS INTEGER) AS non_physical_assaults_on_operators_security_events_only,
        SAFE_CAST(minor_physical_assaults_on_other_transit_workers AS INTEGER) AS minor_physical_assaults_on_other_transit_workers,
        SAFE_CAST(minor_nonphysical_assaults_on_other_transit_workers AS INTEGER) AS minor_nonphysical_assaults_on_other_transit_workers,
        SAFE_CAST(total_incidents AS INTEGER) AS total_incidents,
        SAFE_CAST(customer AS INTEGER) AS customer,
        SAFE_CAST(worker AS INTEGER) AS worker,
        SAFE_CAST(other AS INTEGER) AS other,
        SAFE_CAST(total_injuries AS INTEGER) AS total_injuries,
        {{ trim_make_empty_string_null('additional_assault_information') }} AS additional_assault_information,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__nonmajor_safety_and_security_events
