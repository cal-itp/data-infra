WITH staging_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_and_facilities_by_agency_and_facility_type') }}
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

fct_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.administrative_and_other_non_passenger_facilities,
        stg.administrative_office_sales,
        stg.agency_voms,
        stg.at_grade_fixed_guideway,
        stg.bus_transfer_center,
        stg.combined_administrative_and,
        stg.elevated_fixed_guideway,
        stg.exclusive_grade_separated,
        stg.ferryboat_terminal,
        stg.general_purpose_maintenance,
        stg.heavy_maintenance_overhaul,
        stg.maintenance_facilities,
        stg.maintenance_facility_service,
        stg.organization_type,
        stg.other_administrative,
        stg.other_passenger_or_parking,
        stg.parking_and_other_passenger_facilities,
        stg.parking_structure,
        stg.passenger_stations_and_terminals,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.revenue_collection_facility,
        stg.simple_at_grade_platform,
        stg.surface_parking_lot,
        stg.total_facilities,
        stg.uace_code,
        stg.underground_fixed_guideway,
        stg.uza_name,
        stg.vehicle_blow_down_facility,
        stg.vehicle_fueling_facility,
        stg.vehicle_testing_facility,
        stg.vehicle_washing_facility,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_stations_and_facilities_by_agency_and_facility_type AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_stations_and_facilities_by_agency_and_facility_type
