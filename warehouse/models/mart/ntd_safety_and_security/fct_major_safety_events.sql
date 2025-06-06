WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
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

fct_major_safety_events AS (
    SELECT
        stg.ntd_id,
        stg.year,
        stg.month,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.type_of_service,
        stg.location_group,
        stg.location,
        stg.event_type,
        stg.customer,
        stg.other,
        stg.worker,
        stg.minor_nonphysical_assaults_on_other_transit_workers,
        stg.total_injuries,
        stg.non_physical_assaults_on_operators_security_events_only_,
        stg.total_incidents,
        stg.minor_physical_assaults_on_operators,
        stg.minor_physical_assaults_on_other_transit_workers,
        stg.additional_assault_information,
        stg.sftsecfl,
        stg.reportername,
        stg.dt,
        stg.execution_ts,
        {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.year', 'stg.month',
            'agency.agency_name', 'agency.city', 'agency.state', 'agency.caltrans_district_current',
            'agency.caltrans_district_name_current', 'stg.mode', 'stg.type_of_service', 'stg.location_group',
            'stg.location', 'stg.event_type', 'stg.customer', 'stg.other', 'stg.worker',
            'stg.minor_nonphysical_assaults_on_other_transit_workers', 'stg.total_injuries',
            'stg.non_physical_assaults_on_operators_security_events_only_', 'stg.total_incidents',
            'stg.minor_physical_assaults_on_operators', 'stg.minor_physical_assaults_on_other_transit_workers',
            'stg.additional_assault_information', 'stg.sftsecfl', 'stg.reportername']) }} AS _content_hash
    FROM staging_major_safety_events AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.year = agency.year
)

SELECT * FROM fct_major_safety_events
