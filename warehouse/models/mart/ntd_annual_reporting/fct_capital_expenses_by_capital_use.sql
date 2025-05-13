WITH staging_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_capital_use') }}
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

fct_capital_expenses_by_capital_use AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.report_year', 'stg.modecd', 'stg.typeofservicecd', 'stg.form_type']) }} AS key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.administrative_buildings,
        stg.administrative_buildings_1,
        stg.agency_voms,
        stg.communication_information,
        stg.communication_information_1,
        stg.fare_collection_equipment,
        stg.fare_collection_equipment_1,
        stg.form_type,
        stg.guideway,
        stg.guideway_questionable,
        stg.maintenance_buildings,
        stg.maintenance_buildings_1,
        stg.mode_name,
        stg.mode_voms,
        stg.modecd,
        stg.organization_type,
        stg.other,
        stg.other_questionable,
        stg.other_vehicles,
        stg.other_vehicles_questionable,
        stg.passenger_vehicles,
        stg.passenger_vehicles_1,
        stg.primary_uza_population,
        stg.reduced_reporter,
        stg.reduced_reporter_questionable,
        stg.reporter_type,
        stg.stations,
        stg.stations_questionable,
        stg.total,
        stg.total_questionable,
        stg.typeofservicecd,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_by_capital_use AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_capital_expenses_by_capital_use
