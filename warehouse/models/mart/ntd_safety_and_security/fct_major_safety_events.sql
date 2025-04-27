WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        agency_name,
        year,
        city,
        state,
    FROM {{ ref('dim_agency_information') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_major_safety_events AS (
    SELECT
        agency.agency_name,

        stg.ntd_id,
        stg.yr AS year,

        agency.city,
        agency.state,

        stg.other,
        stg.worker,
        stg.minor_nonphysical_assaults_on_other_transit_workers,
        stg.total_injuries,
        stg.non_physical_assaults_on_operators_security_events_only_,
        stg.total_incidents,
        stg.minor_physical_assaults_on_operators,
        stg.minor_physical_assaults_on_other_transit_workers,
        stg.location_group,
        stg.location,
        stg.eventtype,
        stg.additional_assault_information,
        stg.sftsecfl,
        stg.modecd,
        stg.mo,
        stg.typeofservicecd,
        stg.reportername,
        stg.customer,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_major_safety_events AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.yr = agency.year
)

SELECT * FROM fct_major_safety_events
