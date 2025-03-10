WITH staging_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_capital_use') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_capital_expenses_by_capital_use.*,
        current_dim_organizations.caltrans_district
    FROM staging_capital_expenses_by_capital_use
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_capital_expenses_by_capital_use AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_capital_expenses_by_capital_use
