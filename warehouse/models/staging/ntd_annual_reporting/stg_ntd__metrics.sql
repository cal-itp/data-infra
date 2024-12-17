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
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('agency_voms') }} AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST({{ trim_make_empty_string_null('cost_per_hour') }} AS NUMERIC) AS cost_per_hour,
    {{ trim_make_empty_string_null('cost_per_hour_questionable') }} AS cost_per_hour_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('cost_per_passenger') }} AS NUMERIC) AS cost_per_passenger,
    {{ trim_make_empty_string_null('cost_per_passenger_1') }} AS cost_per_passenger_1,
    SAFE_CAST({{ trim_make_empty_string_null('cost_per_passenger_mile') }} AS NUMERIC) AS cost_per_passenger_mile,
    {{ trim_make_empty_string_null('cost_per_passenger_mile_1') }} AS cost_per_passenger_mile_1,
    SAFE_CAST({{ trim_make_empty_string_null('fare_revenues_earned') }} AS NUMERIC) AS fare_revenues_earned,
    {{ trim_make_empty_string_null('fare_revenues_earned_1') }} AS fare_revenues_earned_1,
    SAFE_CAST({{ trim_make_empty_string_null('fare_revenues_per_total') }} AS NUMERIC) AS fare_revenues_per_total,
    {{ trim_make_empty_string_null('fare_revenues_per_total_1') }} AS fare_revenues_per_total_1,
    SAFE_CAST({{ trim_make_empty_string_null('fare_revenues_per_unlinked') }} AS NUMERIC) AS fare_revenues_per_unlinked,
    {{ trim_make_empty_string_null('fare_revenues_per_unlinked_1') }} AS fare_revenues_per_unlinked_1,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST({{ trim_make_empty_string_null('mode_voms') }} AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST({{ trim_make_empty_string_null('passenger_miles') }} AS NUMERIC) AS passenger_miles,
    {{ trim_make_empty_string_null('passenger_miles_questionable') }} AS passenger_miles_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('passengers_per_hour') }} AS NUMERIC) AS passengers_per_hour,
    {{ trim_make_empty_string_null('passengers_per_hour_1') }} AS passengers_per_hour_1,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_population') }} AS NUMERIC) AS primary_uza_population,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST({{ trim_make_empty_string_null('total_operating_expenses') }} AS NUMERIC) AS total_operating_expenses,
    {{ trim_make_empty_string_null('total_operating_expenses_1') }} AS total_operating_expenses_1,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    SAFE_CAST({{ trim_make_empty_string_null('unlinked_passenger_trips') }} AS NUMERIC) AS unlinked_passenger_trips,
    {{ trim_make_empty_string_null('unlinked_passenger_trips_1') }} AS unlinked_passenger_trips_1,
    SAFE_CAST({{ trim_make_empty_string_null('vehicle_revenue_hours') }} AS NUMERIC) AS vehicle_revenue_hours,
    {{ trim_make_empty_string_null('vehicle_revenue_hours_1') }} AS vehicle_revenue_hours_1,
    SAFE_CAST({{ trim_make_empty_string_null('vehicle_revenue_miles') }} AS NUMERIC) AS vehicle_revenue_miles,
    {{ trim_make_empty_string_null('vehicle_revenue_miles_1') }} AS vehicle_revenue_miles_1,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__metrics
