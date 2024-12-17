WITH external_capital_expenses_by_mode AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_by_mode') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_capital_expenses_by_mode
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_by_mode AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(count_administrative_buildings_q AS NUMERIC) AS count_administrative_buildings_q,
    SAFE_CAST(count_communication_information_q AS NUMERIC) AS count_communication_information_q,
    SAFE_CAST(count_fare_collection_equipment_q AS NUMERIC) AS count_fare_collection_equipment_q,
    SAFE_CAST(count_maintenance_buildings_q AS NUMERIC) AS count_maintenance_buildings_q,
    SAFE_CAST(count_other_q AS NUMERIC) AS count_other_q,
    SAFE_CAST(count_other_vehicles_q AS NUMERIC) AS count_other_vehicles_q,
    SAFE_CAST(count_passenger_vehicles_q AS NUMERIC) AS count_passenger_vehicles_q,
    SAFE_CAST(count_reduced_reporter_q AS NUMERIC) AS count_reduced_reporter_q,
    SAFE_CAST(count_stations_q AS NUMERIC) AS count_stations_q,
    {{ trim_make_empty_string_null('max_agency') }} AS max_agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS max_city,
    {{ trim_make_empty_string_null('max_mode_name') }} AS max_mode_name,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS max_state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('modecd') }} AS modecd,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST(sum_administrative_buildings AS NUMERIC) AS sum_administrative_buildings,
    SAFE_CAST(sum_communication_information AS NUMERIC) AS sum_communication_information,
    SAFE_CAST(sum_fare_collection_equipment AS NUMERIC) AS sum_fare_collection_equipment,
    SAFE_CAST(sum_guideway AS NUMERIC) AS sum_guideway,
    SAFE_CAST(sum_maintenance_buildings AS NUMERIC) AS sum_maintenance_buildings,
    SAFE_CAST(sum_other AS NUMERIC) AS sum_other,
    SAFE_CAST(sum_other_vehicles AS NUMERIC) AS sum_other_vehicles,
    SAFE_CAST(sum_passenger_vehicles AS NUMERIC) AS sum_passenger_vehicles,
    SAFE_CAST(sum_reduced_reporter AS NUMERIC) AS sum_reduced_reporter,
    SAFE_CAST(sum_stations AS NUMERIC) AS sum_stations,
    SAFE_CAST(sum_total AS NUMERIC) AS sum_total,
    {{ trim_make_empty_string_null('typeofservicecd') }} AS typeofservicecd,
    dt,
    execution_ts
FROM stg_ntd__capital_expenses_by_mode
