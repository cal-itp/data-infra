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
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg.form_type,
        stg.administrative_buildings,
        stg.administrative_buildings_1,
        stg.agency_voms,
        stg.communication_information,
        stg.communication_information_1,
        stg.fare_collection_equipment,
        stg.fare_collection_equipment_1,
        stg.guideway,
        stg.guideway_questionable,
        stg.maintenance_buildings,
        stg.maintenance_buildings_1,
        stg.mode_voms,
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
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE stg.key NOT IN ('7b202e36d05a359ebe66c546fa2b0ad1','f39359b88ea57b16e325a2831ed81908','d1a170138bd1bc84702db21a32c8660c',
        'b8cf03629eea7ea725cb80f2a6e9f0f5','7ad8ddc66e0b6d6716cf8e795ddf2c85','df732c77b7e728435f10b52c63054860',
        '166f0664950cccf4af1eda5a5d489beb','10cb814290bf2e31bc81a2c7936d517a')
)

SELECT * FROM fct_capital_expenses_by_capital_use
