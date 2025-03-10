WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_major_safety_events.*,
        current_dim_organizations.caltrans_district
    FROM staging_major_safety_events
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_major_safety_events AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    ntd_id,
    caltrans_district,
    dt,
    execution_ts
FROM fct_major_safety_events
