WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_breakdowns AS (
    SELECT
        stg.agency,
        stg.ntd_id,
        stg.report_year,
        stg.city,
        stg.state,
        stg.agency_voms,
        stg.major_mechanical_failures,
        stg.major_mechanical_failures_1,
        stg.mode,
        stg.mode_name,
        stg.mode_voms,
        stg.organization_type,
        stg.other_mechanical_failures,
        stg.other_mechanical_failures_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_mechanical_failures,
        stg.total_mechanical_failures_1,
        stg.train_miles,
        stg.train_miles_questionable,
        stg.train_revenue_miles,
        stg.train_revenue_miles_1,
        stg.type_of_service,
        stg.uace_code,
        stg.uza_name,
        stg.vehicle_passenger_car_miles,
        stg.vehicle_passenger_car_miles_1,
        stg.vehicle_passenger_car_miles_2,
        stg.vehicle_passenger_car_revenue,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_breakdowns AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_breakdowns
