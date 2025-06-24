WITH staging_monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__monthly_modal_time_series_safety_and_service') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('6924aed27f4367ade41995c1a39b9ee2','aa7cd33a48228993bafcea02e71ff01d','aba850b8be6fecc443628f0214d4f43b',
        'a81b1750d29aebc2bc3467fe32f38b9d','ffa790baa3240de7315997adedf09118','91b21259a46c1824487053fb07b12ce3')
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

fct_monthly_modal_time_series_safety_and_service AS (
    SELECT
        stg.key,
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
        stg.major_non_physical_assaults_on_operators,
        stg.major_non_physical_assaults_on_other_transit_workers,
        stg.major_physical_assaults_on_operators,
        stg.non_major_non_physical_assaults_on_other_transit_workers,
        stg.non_major_physical_assaults_on_other_transit_workers,
        stg.non_major_non_physical_assaults_on_operators,
        stg.total_injuries,
        stg.trespasser_injuries,
        stg.other_injuries,
        stg.other_vehicle_occupant_1,
        stg.pedestrian_walking_along_1,
        stg.pedestrian_in_corsswalk,
        stg.bicyclist_injuries,
        stg.other_worker_injuries,
        stg.total_employee_injuries,
        stg.other_employee_injuries,
        stg.operator_injuries,
        stg.total_other_fatalities,
        stg.other_vehicle_occupant,
        stg.people_waiting_or_leaving_1,
        stg.total_fatalities,
        stg.trespasser_fatalities,
        stg.suicide_injuries,
        stg.collisions_with_other,
        stg.pedestrian_walking_along,
        stg.suicide_fatalities,
        stg.pedestrian_in_crosswalk,
        stg.bicyclist_fatalities,
        stg.other_worker_fatalities,
        stg.passenger_fatalities,
        stg.total_employee_fatalities,
        stg.operator_fatalities,
        stg.people_waiting_or_leaving,
        stg.uace_code,
        stg.total_events_not_otherwise,
        stg.primary_uza_population,
        stg.collisions_with_bus_vehicle,
        stg.total_security_events,
        stg.total_events,
        stg.rail_y_n,
        stg.total_fires,
        stg.total_derailments,
        stg.pedestrian_crossing_tracks,
        stg.total_assaults_on_transit_workers,
        stg.total_collisions,
        stg.collisions_with_rail_vehicle,
        stg.passenger_injuries,
        stg.collisions_with_fixed_object,
        stg.ridership,
        stg.service_area_population,
        stg.collisions_with_person,
        stg.major_physical_assaults_on_other_transit_workers,
        stg.collisions_with_motor_vehicle,
        stg.service_area_sq_miles,
        stg.other_employee_fatalities,
        stg.non_major_physical_assaults_on_operators,
        stg.vehicle_revenue_hours,
        stg.pedestrian_not_in_crosswalk_1,
        stg.vehicle_revenue_miles,
        stg.vehicles,
        stg.organization_type,
        stg.pedestrian_crossing_tracks_1,
        stg.primary_uza_sq_miles,
        stg.primary_uza_name,
        stg.agency AS source_agency,
        stg.total_other_injuries,
        stg.other_fatalities,
        stg.pedestrian_not_in_crosswalk,
        stg.dt,
        stg.execution_ts
    FROM staging_monthly_modal_time_series_safety_and_service AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.year = agency.year
)

SELECT * FROM fct_monthly_modal_time_series_safety_and_service
