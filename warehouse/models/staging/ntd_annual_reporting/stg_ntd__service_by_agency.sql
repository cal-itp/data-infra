WITH external_service_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__service_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_service_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__service_by_agency AS (
    SELECT
        {{ trim_make_empty_string_null('CAST(_5_digit_ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
        {{ trim_make_empty_string_null('max_city') }} AS city,
        {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
        {{ trim_make_empty_string_null('max_primary_uza_area_sq_miles') }} AS max_primary_uza_area_sq_miles,
        SAFE_CAST(max_primary_uza_code AS NUMERIC) AS max_primary_uza_code,
        {{ trim_make_empty_string_null('max_primary_uza_name') }} AS max_primary_uza_name,
        SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
        {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
        SAFE_CAST(max_service_area_population AS NUMERIC) AS max_service_area_population,
        SAFE_CAST(max_service_area_sq_miles AS NUMERIC) AS max_service_area_sq_miles,
        {{ trim_make_empty_string_null('max_state') }} AS state,
        SAFE_CAST(report_year AS INT64) AS report_year,
        SAFE_CAST(sum_actual_vehicles_passenger_car_deadhead_hours AS NUMERIC) AS sum_actual_vehicles_passenger_car_deadhead_hours,
        SAFE_CAST(sum_actual_vehicles_passenger_car_hours AS NUMERIC) AS sum_actual_vehicles_passenger_car_hours,
        SAFE_CAST(sum_actual_vehicles_passenger_car_miles AS NUMERIC) AS sum_actual_vehicles_passenger_car_miles,
        SAFE_CAST(sum_actual_vehicles_passenger_car_revenue_hours AS NUMERIC) AS sum_actual_vehicles_passenger_car_revenue_hours,
        SAFE_CAST(sum_actual_vehicles_passenger_car_revenue_miles AS NUMERIC) AS sum_actual_vehicles_passenger_car_revenue_miles,
        SAFE_CAST(sum_actual_vehicles_passenger_deadhead_miles AS NUMERIC) AS sum_actual_vehicles_passenger_deadhead_miles,
        SAFE_CAST(sum_ada_upt AS NUMERIC) AS sum_ada_upt,
        SAFE_CAST(sum_charter_service_hours AS NUMERIC) AS sum_charter_service_hours,
        SAFE_CAST(sum_directional_route_miles AS NUMERIC) AS sum_directional_route_miles,
        SAFE_CAST(sum_passenger_miles AS NUMERIC) AS sum_passenger_miles,
        SAFE_CAST(sum_scheduled_vehicles_passenger_car_revenue_miles AS NUMERIC) AS sum_scheduled_vehicles_passenger_car_revenue_miles,
        SAFE_CAST(sum_school_bus_hours AS NUMERIC) AS sum_school_bus_hours,
        SAFE_CAST(sum_sponsored_service_upt AS NUMERIC) AS sum_sponsored_service_upt,
        SAFE_CAST(sum_train_deadhead_hours AS NUMERIC) AS sum_train_deadhead_hours,
        SAFE_CAST(sum_train_deadhead_miles AS NUMERIC) AS sum_train_deadhead_miles,
        SAFE_CAST(sum_train_hours AS NUMERIC) AS sum_train_hours,
        SAFE_CAST(sum_train_miles AS NUMERIC) AS sum_train_miles,
        SAFE_CAST(sum_train_revenue_hours AS NUMERIC) AS sum_train_revenue_hours,
        SAFE_CAST(sum_train_revenue_miles AS NUMERIC) AS sum_train_revenue_miles,
        SAFE_CAST(sum_trains_in_operation AS NUMERIC) AS sum_trains_in_operation,
        SAFE_CAST(sum_unlinked_passenger_trips_upt AS NUMERIC) AS sum_unlinked_passenger_trips_upt,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__service_by_agency
