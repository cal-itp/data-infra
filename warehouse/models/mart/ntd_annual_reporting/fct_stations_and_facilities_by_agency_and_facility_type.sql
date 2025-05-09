WITH staging_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_and_facilities_by_agency_and_facility_type') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT
        stg.agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
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

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_stations_and_facilities_by_agency_and_facility_type AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_stations_and_facilities_by_agency_and_facility_type
