WITH external_capital_expenses_for_existing_service AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__capital_expenses_for_existing_service') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_capital_expenses_for_existing_service
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__capital_expenses_for_existing_service AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year']) }} AS key,
        {{ trim_make_empty_string_null('form_type') }} AS form_type,
        {{ trim_make_empty_string_null('max_agency') }} AS agency,
        SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
        {{ trim_make_empty_string_null('max_city') }} AS city,
        {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
        SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
        {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
        {{ trim_make_empty_string_null('max_state') }} AS state,
        {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
        {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        SAFE_CAST(report_year AS INT64) AS report_year,
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
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__capital_expenses_for_existing_service
