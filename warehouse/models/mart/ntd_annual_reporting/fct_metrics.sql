WITH staging_metrics AS (
    SELECT *
    FROM {{ ref('stg_ntd__metrics') }}
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
        staging_metrics.*,
        current_dim_organizations.caltrans_district
    FROM staging_metrics
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_metrics AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency,
    agency_voms,
    city,
    cost_per_hour,
    cost_per_hour_questionable,
    cost_per_passenger,
    cost_per_passenger_1,
    cost_per_passenger_mile,
    cost_per_passenger_mile_1,
    fare_revenues_earned,
    fare_revenues_earned_1,
    fare_revenues_per_total,
    fare_revenues_per_total_1,
    fare_revenues_per_unlinked,
    fare_revenues_per_unlinked_1,
    mode,
    mode_name,
    mode_voms,
    ntd_id,
    organization_type,
    passenger_miles,
    passenger_miles_questionable,
    passengers_per_hour,
    passengers_per_hour_1,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    total_operating_expenses,
    total_operating_expenses_1,
    type_of_service,
    unlinked_passenger_trips,
    unlinked_passenger_trips_1,
    vehicle_revenue_hours,
    vehicle_revenue_hours_1,
    vehicle_revenue_miles,
    vehicle_revenue_miles_1,
    uace_code,
    uza_name,
    caltrans_district,
    dt,
    execution_ts
FROM fct_metrics
