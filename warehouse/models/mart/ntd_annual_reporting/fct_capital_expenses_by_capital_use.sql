WITH staging_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_by_capital_use') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_capital_expenses_by_capital_use AS (
    SELECT
        stg.administrative_buildings,
        stg.administrative_buildings_1,
        stg.agency,
        stg.agency_voms,
        stg.city,
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
        stg.ntd_id,
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
        stg.report_year,
        stg.reporter_type,
        stg.state,
        stg.stations,
        stg.stations_questionable,
        stg.total,
        stg.total_questionable,
        stg.typeofservicecd,
        stg.uace_code,
        stg.uza_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_by_capital_use AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_capital_expenses_by_capital_use
