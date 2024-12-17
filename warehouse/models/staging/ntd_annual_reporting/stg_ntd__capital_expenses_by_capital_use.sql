WITH external_capital_expenses_by_capital_use AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_by_capital_use') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_capital_expenses_by_capital_use
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_by_capital_use AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST({{ trim_make_empty_string_null('administrative_buildings') }} AS NUMERIC) AS administrative_buildings,
    {{ trim_make_empty_string_null('administrative_buildings_1') }} AS administrative_buildings_1,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('agency_voms') }} AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST({{ trim_make_empty_string_null('communication_information') }} AS NUMERIC) AS communication_information,
    {{ trim_make_empty_string_null('communication_information_1') }} AS communication_information_1,
    SAFE_CAST({{ trim_make_empty_string_null('fare_collection_equipment') }} AS NUMERIC) AS fare_collection_equipment,
    {{ trim_make_empty_string_null('fare_collection_equipment_1') }} AS fare_collection_equipment_1,
    {{ trim_make_empty_string_null('form_type') }} AS form_type,
    SAFE_CAST({{ trim_make_empty_string_null('guideway') }} AS NUMERIC) AS guideway,
    SAFE_CAST({{ trim_make_empty_string_null('guideway_questionable') }} AS NUMERIC) AS guideway_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('maintenance_buildings') }} AS NUMERIC) AS maintenance_buildings,
    {{ trim_make_empty_string_null('maintenance_buildings_1') }} AS maintenance_buildings_1,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    SAFE_CAST({{ trim_make_empty_string_null('mode_voms') }} AS NUMERIC) AS mode_voms,
    {{ trim_make_empty_string_null('modecd') }} AS modecd,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST({{ trim_make_empty_string_null('other') }} AS NUMERIC) AS other,
    {{ trim_make_empty_string_null('other_questionable') }} AS other_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('other_vehicles') }} AS NUMERIC) AS other_vehicles,
    {{ trim_make_empty_string_null('other_vehicles_questionable') }} AS other_vehicles_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('passenger_vehicles') }} AS NUMERIC) AS passenger_vehicles,
    {{ trim_make_empty_string_null('passenger_vehicles_1') }} AS passenger_vehicles_1,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_population') }} AS NUMERIC) AS primary_uza_population,
    SAFE_CAST({{ trim_make_empty_string_null('reduced_reporter') }} AS NUMERIC) AS reduced_reporter,
    {{ trim_make_empty_string_null('reduced_reporter_questionable') }} AS reduced_reporter_questionable,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST({{ trim_make_empty_string_null('stations') }} AS NUMERIC) AS stations,
    {{ trim_make_empty_string_null('stations_questionable') }} AS stations_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('total') }} AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('total_questionable') }} AS total_questionable,
    {{ trim_make_empty_string_null('typeofservicecd') }} AS typeofservicecd,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__capital_expenses_by_capital_use
