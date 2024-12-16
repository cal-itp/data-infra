WITH staging_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__stations_and_facilities_by_agency_and_facility_type') }}
),

fct_stations_and_facilities_by_agency_and_facility_type AS (
    SELECT *
    FROM staging_stations_and_facilities_by_agency_and_facility_type
)

SELECT * FROM fct_stations_and_facilities_by_agency_and_facility_type
