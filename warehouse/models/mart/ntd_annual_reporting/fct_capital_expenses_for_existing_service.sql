WITH staging_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_for_existing_service') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_capital_expenses_for_existing_service AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.form_type,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_administrative_buildings,
        stg.sum_communication_information,
        stg.sum_fare_collection_equipment,
        stg.sum_guideway,
        stg.sum_maintenance_buildings,
        stg.sum_other,
        stg.sum_other_vehicles,
        stg.sum_passenger_vehicles,
        stg.sum_reduced_reporter,
        stg.sum_stations,
        stg.sum_total,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_for_existing_service AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_capital_expenses_for_existing_service
