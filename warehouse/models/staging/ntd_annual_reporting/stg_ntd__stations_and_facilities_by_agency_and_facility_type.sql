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
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__stations_and_facilities_by_agency_and_facility_type
