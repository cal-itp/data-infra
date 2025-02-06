WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_major_safety_events AS (
    SELECT
        staging_major_safety_events.*,
        dim_organizations.caltrans_district
    FROM staging_major_safety_events
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_major_safety_events.yr <= 2022 THEN
                staging_major_safety_events.ntdid = dim_organizations.ntd_id_2022
            ELSE
                staging_major_safety_events.ntdid = dim_organizations.ntd_id
        END
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_major_safety_events
