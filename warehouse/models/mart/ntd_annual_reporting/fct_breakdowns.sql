WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns') }}
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
        staging_breakdowns.*,
        current_dim_organizations.caltrans_district
    FROM staging_breakdowns
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_breakdowns AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    agency_voms,
    city,
    major_mechanical_failures,
    major_mechanical_failures_1,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    other_mechanical_failures,
    other_mechanical_failures_1,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_mechanical_failures,
    total_mechanical_failures_1,
    train_miles,
    train_miles_questionable,
    train_revenue_miles,
    train_revenue_miles_1,
    type_of_service,
    uace_code,
    uza_name,
    vehicle_passenger_car_miles,
    vehicle_passenger_car_miles_1,
    vehicle_passenger_car_miles_2,
    vehicle_passenger_car_revenue,
    caltrans_district,
    dt,
    execution_ts
FROM fct_breakdowns
