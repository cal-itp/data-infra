WITH staging_master AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__master') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__master AS (
    SELECT *
    FROM staging_master
)

SELECT
    ntd_id,
    legacy_ntd_id,
    agency,
    mode,
    tos,
    _3_mode,
    mode_type_of_service_status,
    reporter_type,
    organization_type,
    hq_city,
    hq_state,
    uace_cd,
    uza_name,
    uza_sq_miles,
    uza_population,
    service_area_population,
    service_area_sq_miles,
    last_closed_report_year,
    last_closed_fy_end_month,
    last_closed_fy_end_year,
    passenger_miles_fy,
    unlinked_passenger_trips_fy,
    avg_trip_length_fy,
    fares_fy,
    operating_expenses_fy,
    avg_cost_per_trip_fy,
    avg_fares_per_trip_fy,
    dt,
    execution_ts
FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__master
