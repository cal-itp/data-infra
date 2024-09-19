WITH external_2022_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__stations_and_facilities_by_agency_and_facility_type') }}
),

stg_ntd_annual_data_tables__2022__stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM external_2022_stations_and_facilities_by_agency_and_facility_type
)

SELECT * FROM stg_ntd_annual_data_tables__2022__stations_and_facilities_by_agency_and_facility_type
