WITH staging_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_and_facilities_by_agency_and_facility_type') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT
        staging_stations_and_facilities_by_agency_and_facility_type.*,
        dim_organizations.caltrans_district
    FROM staging_stations_and_facilities_by_agency_and_facility_type
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_stations_and_facilities_by_agency_and_facility_type.report_year = 2022 THEN
                staging_stations_and_facilities_by_agency_and_facility_type.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_stations_and_facilities_by_agency_and_facility_type.ntd_id = dim_organizations.ntd_id
        END
)

SELECT
    administrative_and_other_non_passenger_facilities,
    administrative_office_sales,
    agency,
    agency_voms,
    at_grade_fixed_guideway,
    bus_transfer_center,
    city,
    combined_administrative_and,
    elevated_fixed_guideway,
    exclusive_grade_separated,
    ferryboat_terminal,
    general_purpose_maintenance,
    heavy_maintenance_overhaul,
    maintenance_facilities,
    maintenance_facility_service,
    ntd_id,
    organization_type,
    other_administrative,
    other_passenger_or_parking,
    parking_and_other_passenger_facilities,
    parking_structure,
    passenger_stations_and_terminals,
    primary_uza_population,
    report_year,
    reporter_type,
    revenue_collection_facility,
    simple_at_grade_platform,
    state,
    surface_parking_lot,
    total_facilities,
    uace_code,
    underground_fixed_guideway,
    uza_name,
    vehicle_blow_down_facility,
    vehicle_fueling_facility,
    vehicle_testing_facility,
    vehicle_washing_facility,
    caltrans_district,
    dt,
    execution_ts
FROM fct_stations_and_facilities_by_agency_and_facility_type
