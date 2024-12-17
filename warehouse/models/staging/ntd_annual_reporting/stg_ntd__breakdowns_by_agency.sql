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
    SAFE_CAST(count_major_mechanical_failures_questionable AS NUMERIC) AS count_major_mechanical_failures_questionable,
    SAFE_CAST(count_other_mechanical_failures_questionable AS NUMERIC) AS count_other_mechanical_failures_questionable,
    SAFE_CAST(count_total_mechanical_failures_questionable AS NUMERIC) AS count_total_mechanical_failures_questionable,
    SAFE_CAST(count_train_miles_questionable AS NUMERIC) AS count_train_miles_questionable,
    SAFE_CAST(count_train_revenue_miles_questionable AS NUMERIC) AS count_train_revenue_miles_questionable,
    SAFE_CAST(count_vehicle_passenger_car_miles_questionable AS NUMERIC) AS count_vehicle_passenger_car_miles_questionable,
    {{ trim_make_empty_string_null('max_agency') }} AS max_agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS max_city,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS max_state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST(sum_major_mechanical_failures AS NUMERIC) AS sum_major_mechanical_failures,
    SAFE_CAST(sum_other_mechanical_failures AS NUMERIC) AS sum_other_mechanical_failures,
    SAFE_CAST(sum_total_mechanical_failures AS NUMERIC) AS sum_total_mechanical_failures,
    SAFE_CAST(sum_train_miles AS NUMERIC) AS sum_train_miles,
    SAFE_CAST(sum_train_revenue_miles AS NUMERIC) AS sum_train_revenue_miles,
    SAFE_CAST(sum_vehicle_passenger_car_miles AS NUMERIC) AS sum_vehicle_passenger_car_miles,
    SAFE_CAST(sum_vehicle_passenger_car_revenue AS NUMERIC) AS sum_vehicle_passenger_car_revenue,
    dt,
    execution_ts
FROM stg_ntd__breakdowns_by_agency
