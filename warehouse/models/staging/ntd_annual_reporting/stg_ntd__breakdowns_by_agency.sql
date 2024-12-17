WITH external_breakdowns_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__breakdowns_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_breakdowns_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__breakdowns_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    count_major_mechanical_failures_questionable,
    count_other_mechanical_failures_questionable,
    count_total_mechanical_failures_questionable,
    count_train_miles_questionable,
    count_train_revenue_miles_questionable,
    count_vehicle_passenger_car_miles_questionable,
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_major_mechanical_failures,
    sum_other_mechanical_failures,
    sum_total_mechanical_failures,
    sum_train_miles,
    sum_train_revenue_miles,
    sum_vehicle_passenger_car_miles,
    sum_vehicle_passenger_car_revenue,
    dt,
    execution_ts
FROM stg_ntd__breakdowns_by_agency
