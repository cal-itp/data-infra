WITH external_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__stations_and_facilities_by_agency_and_facility_type') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_stations_and_facilities_by_agency_and_facility_type
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__stations_and_facilities_by_agency_and_facility_type AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year']) }} AS key,
        SAFE_CAST(administrative_and_other_non_passenger_facilities AS NUMERIC) AS administrative_and_other_non_passenger_facilities,
        SAFE_CAST(administrative_office_sales AS NUMERIC) AS administrative_office_sales,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        SAFE_CAST(at_grade_fixed_guideway AS NUMERIC) AS at_grade_fixed_guideway,
        SAFE_CAST(bus_transfer_center AS NUMERIC) AS bus_transfer_center,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(combined_administrative_and AS NUMERIC) AS combined_administrative_and,
        SAFE_CAST(elevated_fixed_guideway AS NUMERIC) AS elevated_fixed_guideway,
        SAFE_CAST(exclusive_grade_separated AS NUMERIC) AS exclusive_grade_separated,
        SAFE_CAST(ferryboat_terminal AS NUMERIC) AS ferryboat_terminal,
        SAFE_CAST(general_purpose_maintenance AS NUMERIC) AS general_purpose_maintenance,
        SAFE_CAST(heavy_maintenance_overhaul AS NUMERIC) AS heavy_maintenance_overhaul,
        SAFE_CAST(maintenance_facilities AS NUMERIC) AS maintenance_facilities,
        SAFE_CAST(maintenance_facility_service AS NUMERIC) AS maintenance_facility_service,
        {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(other_administrative AS NUMERIC) AS other_administrative,
        SAFE_CAST(other_passenger_or_parking AS NUMERIC) AS other_passenger_or_parking,
        SAFE_CAST(parking_and_other_passenger_facilities AS NUMERIC) AS parking_and_other_passenger_facilities,
        SAFE_CAST(parking_structure AS NUMERIC) AS parking_structure,
        SAFE_CAST(passenger_stations_and_terminals AS NUMERIC) AS passenger_stations_and_terminals,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        SAFE_CAST(revenue_collection_facility AS NUMERIC) AS revenue_collection_facility,
        SAFE_CAST(simple_at_grade_platform AS NUMERIC) AS simple_at_grade_platform,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(surface_parking_lot AS NUMERIC) AS surface_parking_lot,
        SAFE_CAST(total_facilities AS NUMERIC) AS total_facilities,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        SAFE_CAST(underground_fixed_guideway AS NUMERIC) AS underground_fixed_guideway,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        SAFE_CAST(vehicle_blow_down_facility AS NUMERIC) AS vehicle_blow_down_facility,
        SAFE_CAST(vehicle_fueling_facility AS NUMERIC) AS vehicle_fueling_facility,
        SAFE_CAST(vehicle_testing_facility AS NUMERIC) AS vehicle_testing_facility,
        SAFE_CAST(vehicle_washing_facility AS NUMERIC) AS vehicle_washing_facility,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__stations_and_facilities_by_agency_and_facility_type
