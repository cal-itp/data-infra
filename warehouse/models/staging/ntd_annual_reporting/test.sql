WITH external_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__service_by_mode_and_time_period') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_service_by_mode_and_time_period
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__service_by_mode_and_time_period AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['_5_digit_ntd_id', 'report_year', 'mode', 'type_of_service', 'time_period']) }} AS key,
        {{ trim_make_empty_string_null('_5_digit_ntd_id') }} AS ntd_id,
        PARSE_BIGNUMERIC(CAST actual_vehicles_passenger_car_deadhead_hours AS STRING) AS actual_vehicles_passenger_car_deadhead_hours,
        PARSE_BIGNUMERIC(CAST actual_vehicles_passenger_car_hours AS STRING) AS actual_vehicles_passenger_car_hours,
        PARSE_BIGNUMERIC(CAST actual_vehicles_passenger_car_miles AS STRING) AS actual_vehicles_passenger_car_miles,
        PARSE_BIGNUMERIC(CAST actual_vehicles_passenger_car_revenue_hours AS STRING) AS actual_vehicles_passenger_car_revenue_hours,

    FROM get_latest_extract
)

SELECT * FROM stg_ntd__service_by_mode_and_time_period
