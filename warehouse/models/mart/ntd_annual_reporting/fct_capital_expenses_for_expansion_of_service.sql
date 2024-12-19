WITH staging_capital_expenses_for_expansion_of_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_for_expansion_of_service') }}
),

dim_organizations AS (
    SELECT *
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

fct_capital_expenses_for_expansion_of_service AS (
    SELECT
        staging_capital_expenses_for_expansion_of_service.*,
        dim_organizations.caltrans_district
    FROM staging_capital_expenses_for_expansion_of_service
    LEFT JOIN dim_organizations
        ON CASE
            WHEN staging_capital_expenses_for_expansion_of_service.report_year = 2022 THEN
                staging_capital_expenses_for_expansion_of_service.ntd_id = dim_organizations.ntd_id_2022
            ELSE
                staging_capital_expenses_for_expansion_of_service.ntd_id = dim_organizations.ntd_id
        END
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
FROM fct_capital_expenses_for_expansion_of_service
