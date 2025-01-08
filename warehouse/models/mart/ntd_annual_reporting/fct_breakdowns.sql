WITH staging_breakdowns AS (
    SELECT *
    FROM {{ ref('stg_ntd__breakdowns') }}
),

fct_breakdowns AS (
    SELECT *
    FROM staging_breakdowns
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
    dt,
    execution_ts
FROM fct_breakdowns
