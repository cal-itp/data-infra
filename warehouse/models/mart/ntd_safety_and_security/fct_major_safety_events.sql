WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

fct_major_safety_events AS (
    SELECT *
    FROM staging_major_safety_events
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
FROM fct_major_safety_events
