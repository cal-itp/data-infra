WITH external_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_for_expansion_of_service') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_capital_expenses_for_expansion_of_service
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    form_type,
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_administrative_buildings,
    sum_communication_information,
    sum_fare_collection_equipment,
    sum_guideway,
    sum_maintenance_buildings,
    sum_other,
    sum_other_vehicles,
    sum_passenger_vehicles,
    sum_reduced_reporter,
    sum_stations,
    sum_total,
    dt,
    execution_ts
FROM stg_ntd__capital_expenses_for_expansion_of_service
