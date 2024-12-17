WITH external_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__funding_sources_directly_generated') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_funding_sources_directly_generated
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__funding_sources_directly_generated AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST({{ trim_make_empty_string_null('advertising') }} AS NUMERIC) AS advertising,
    {{ trim_make_empty_string_null('advertising_questionable') }} AS advertising_questionable,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST({{ trim_make_empty_string_null('agency_voms') }} AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    SAFE_CAST({{ trim_make_empty_string_null('concessions') }} AS NUMERIC) AS concessions,
    {{ trim_make_empty_string_null('concessions_questionable') }} AS concessions_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('fares') }} AS NUMERIC) AS fares,
    {{ trim_make_empty_string_null('fares_questionable') }} AS fares_questionable,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST({{ trim_make_empty_string_null('other') }} AS NUMERIC) AS other,
    {{ trim_make_empty_string_null('other_questionable') }} AS other_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('park_and_ride') }} AS NUMERIC) AS park_and_ride,
    {{ trim_make_empty_string_null('park_and_ride_questionable') }} AS park_and_ride_questionable,
    SAFE_CAST({{ trim_make_empty_string_null('primary_uza_population') }} AS NUMERIC) AS primary_uza_population,
    SAFE_CAST({{ trim_make_empty_string_null('purchased_transportation') }} AS NUMERIC) AS purchased_transportation,
    {{ trim_make_empty_string_null('purchased_transportation_1') }} AS purchased_transportation_1,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    SAFE_CAST({{ trim_make_empty_string_null('total') }} AS NUMERIC) AS total,
    {{ trim_make_empty_string_null('total_questionable') }} AS total_questionable,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__funding_sources_directly_generated
