WITH external_metrics AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__metrics') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_metrics
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__metrics AS (
    SELECT *
    FROM get_latest_extract
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
    dt,
    execution_ts
FROM stg_ntd__metrics
