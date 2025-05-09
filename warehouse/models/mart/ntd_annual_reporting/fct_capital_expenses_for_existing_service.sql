WITH staging_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenses_for_existing_service') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_capital_expenses_for_existing_service AS (
    SELECT
        stg.max_agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.max_city AS city,
        stg.max_state AS state,
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

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_capital_expenses_for_existing_service AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_capital_expenses_for_existing_service
