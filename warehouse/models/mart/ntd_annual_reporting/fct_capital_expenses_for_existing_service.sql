WITH staging_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_for_existing_service') }}
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
        staging_capital_expenses_for_existing_service.*,
        current_dim_organizations.caltrans_district
    FROM staging_capital_expenses_for_existing_service
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_capital_expenses_for_existing_service AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_capital_expenses_for_existing_service
