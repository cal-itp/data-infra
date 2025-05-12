WITH staging_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_mode') }}
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

fct_capital_expenses_by_mode AS (
    SELECT
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.count_administrative_buildings_q,
        stg.count_communication_information_q,
        stg.count_fare_collection_equipment_q,
        stg.count_maintenance_buildings_q,
        stg.count_other_q,
        stg.count_other_vehicles_q,
        stg.count_passenger_vehicles_q,
        stg.count_reduced_reporter_q,
        stg.count_stations_q,
        stg.max_agency_voms,
        stg.max_mode_name,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.modecd,
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
        stg.typeofservicecd,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_by_mode AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_capital_expenses_by_mode
