WITH external_major_safety_events AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__major_safety_events') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_major_safety_events
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__major_safety_events AS (
    SELECT
        SAFE_CAST(other AS INTEGER) AS other,
        SAFE_CAST(worker AS INTEGER) AS worker,
        SAFE_CAST(minor_nonphysical_assaults_on_other_transit_workers AS INTEGER) AS minor_nonphysical_assaults_on_other_transit_workers,
        SAFE_CAST(total_injuries AS INTEGER) AS total_injuries,
        SAFE_CAST(non_physical_assaults_on_operators_security_events_only_ AS INTEGER) AS non_physical_assaults_on_operators_security_events_only_,
        SAFE_CAST(total_incidents AS INTEGER) AS total_incidents,
        SAFE_CAST(minor_physical_assaults_on_operators AS INTEGER) AS minor_physical_assaults_on_operators,
        SAFE_CAST(minor_physical_assaults_on_other_transit_workers AS INTEGER) AS minor_physical_assaults_on_other_transit_workers,
        {{ trim_make_empty_string_null('location_group') }} AS location_group,
        {{ trim_make_empty_string_null('location') }} AS location,
        {{ trim_make_empty_string_null('eventtype') }} AS event_type,
        {{ trim_make_empty_string_null('additional_assault_information') }} AS additional_assault_information,
        {{ trim_make_empty_string_null('sftsecfl') }} AS sftsecfl,
        SAFE_CAST(yr AS INTEGER) AS year,
        {{ trim_make_empty_string_null('modecd') }} AS mode,
        {{ trim_make_empty_string_null('mo') }} AS month,
        {{ trim_make_empty_string_null('typeofservicecd') }} AS type_of_service,
        {{ trim_make_empty_string_null('reportername') }} AS reportername,
        SAFE_CAST(customer AS INTEGER) AS customer,
        {{ trim_make_empty_string_null('CAST(ntdid AS STRING)') }} AS ntd_id,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__major_safety_events
