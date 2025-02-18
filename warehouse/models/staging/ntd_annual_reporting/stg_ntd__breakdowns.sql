WITH external_breakdowns AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__breakdowns') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_breakdowns
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__breakdowns AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST(major_mechanical_failures AS NUMERIC) AS major_mechanical_failures,
    {{ trim_make_empty_string_null('major_mechanical_failures_1') }} AS major_mechanical_failures_1,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(other_mechanical_failures AS NUMERIC) AS other_mechanical_failures,
    {{ trim_make_empty_string_null('other_mechanical_failures_1') }} AS other_mechanical_failures_1,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    SAFE_CAST(report_year AS INT64) AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST(total_mechanical_failures AS NUMERIC) AS total_mechanical_failures,
    {{ trim_make_empty_string_null('total_mechanical_failures_1') }} AS total_mechanical_failures_1,
    SAFE_CAST(train_miles AS NUMERIC) AS train_miles,
    {{ trim_make_empty_string_null('train_miles_questionable') }} AS train_miles_questionable,
    SAFE_CAST(train_revenue_miles AS NUMERIC) AS train_revenue_miles,
    {{ trim_make_empty_string_null('train_revenue_miles_1') }} AS train_revenue_miles_1,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    SAFE_CAST(vehicle_passenger_car_miles AS NUMERIC) AS vehicle_passenger_car_miles,
    {{ trim_make_empty_string_null('vehicle_passenger_car_miles_1') }} AS vehicle_passenger_car_miles_1,
    {{ trim_make_empty_string_null('vehicle_passenger_car_miles_2') }} AS vehicle_passenger_car_miles_2,
    SAFE_CAST(vehicle_passenger_car_revenue AS NUMERIC) AS vehicle_passenger_car_revenue,
    dt,
    execution_ts
FROM stg_ntd__breakdowns
