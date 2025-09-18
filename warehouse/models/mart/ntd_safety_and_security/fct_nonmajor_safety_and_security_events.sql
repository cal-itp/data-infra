WITH staging_nonmajor_safety_and_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__nonmajor_safety_and_security_events') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_nonmajor_safety_and_security_events AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.reporter_name,
        stg.mode_cd,
        stg.type_of_service_cd,
        stg.month,
        stg.safety_security_flag,
        stg.event_type,
        stg.location,
        stg.location_group,
        stg.minor_physical_assaults_on_operators,
        stg.non_physical_assaults_on_operators_security_events_only,
        stg.minor_physical_assaults_on_other_transit_workers,
        stg.minor_nonphysical_assaults_on_other_transit_workers,
        stg.total_incidents,
        stg.customer,
        stg.worker,
        stg.other,
        stg.total_injuries,
        stg.additional_assault_information,
        stg.dt,
        stg.execution_ts
    FROM staging_nonmajor_safety_and_security_events AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.year = agency.year
)

SELECT * FROM fct_nonmajor_safety_and_security_events
