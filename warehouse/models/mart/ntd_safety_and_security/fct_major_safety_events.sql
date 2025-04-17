WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
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
        stg.yr,
        stg.modecd,
        stg.mo,
        stg.typeofservicecd,
        stg.reportername,
        stg.customer,
        stg.ntd_id,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_major_safety_events AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_major_safety_events
