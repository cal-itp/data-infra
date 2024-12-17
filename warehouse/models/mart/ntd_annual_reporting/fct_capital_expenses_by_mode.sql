WITH staging_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_mode') }}
),

fct_capital_expenses_by_mode AS (
    SELECT *
    FROM staging_capital_expenses_by_mode
)

SELECT
    count_administrative_buildings_q,
    count_communication_information_q,
    count_fare_collection_equipment_q,
    count_maintenance_buildings_q,
    count_other_q,
    count_other_vehicles_q,
    count_passenger_vehicles_q,
    count_reduced_reporter_q,
    count_stations_q,
    max_agency,
    max_agency_voms,
    max_city,
    max_mode_name,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    modecd,
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
    typeofservicecd,
    dt,
    execution_ts
FROM fct_capital_expenses_by_mode
