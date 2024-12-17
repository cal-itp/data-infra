WITH external_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_by_capital_use') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_capital_expenses_by_capital_use
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_by_capital_use AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    administrative_buildings,
    administrative_buildings_1,
    agency,
    agency_voms,
    city,
    communication_information,
    communication_information_1,
    fare_collection_equipment,
    fare_collection_equipment_1,
    form_type,
    guideway,
    guideway_questionable,
    maintenance_buildings,
    maintenance_buildings_1,
    mode_name,
    mode_voms,
    modecd,
    ntd_id,
    organization_type,
    other,
    other_questionable,
    other_vehicles,
    other_vehicles_questionable,
    passenger_vehicles,
    passenger_vehicles_1,
    primary_uza_population,
    reduced_reporter,
    reduced_reporter_questionable,
    report_year,
    reporter_type,
    state,
    stations,
    stations_questionable,
    total,
    total_questionable,
    typeofservicecd,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__capital_expenses_by_capital_use
