WITH external_major_safety_events AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'multi_year__major_safety_events') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_major_safety_events
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__major_safety_events AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    other,
    worker,
    minor_nonphysical_assaults_on_other_transit_workers,
    total_injuries,
    non_physical_assaults_on_operators_security_events_only_,
    total_incidents,
    minor_physical_assaults_on_operators,
    minor_physical_assaults_on_other_transit_workers,
    location_group,
    location,
    eventtype,
    additional_assault_information,
    sftsecfl,
    yr,
    modecd,
    mo,
    typeofservicecd,
    reportername,
    customer,
    ntdid,
    dt,
    execution_ts
FROM stg_ntd__major_safety_events
