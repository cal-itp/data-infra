WITH external_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__stations_by_mode_and_age') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_stations_by_mode_and_age
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__stations_by_mode_and_age AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year', 'modes', 'facility_type']) }} AS key,
        SAFE_CAST(_1940s AS NUMERIC) AS _1940s,
        SAFE_CAST(_1950s AS NUMERIC) AS _1950s,
        SAFE_CAST(_1960s AS NUMERIC) AS _1960s,
        SAFE_CAST(_1970s AS NUMERIC) AS _1970s,
        SAFE_CAST(_1980s AS NUMERIC) AS _1980s,
        SAFE_CAST(_1990s AS NUMERIC) AS _1990s,
        SAFE_CAST(_2000s AS NUMERIC) AS _2000s,
        SAFE_CAST(_2010s AS NUMERIC) AS _2010s,
        SAFE_CAST(_2020s AS NUMERIC) AS _2020s,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        {{ trim_make_empty_string_null('city') }} AS city,
        {{ trim_make_empty_string_null('facility_type') }} AS facility_type,
        {{ trim_make_empty_string_null('mode_names') }} AS mode_names,
        {{ trim_make_empty_string_null('modes') }} AS modes,
        {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(pre1940 AS NUMERIC) AS pre1940,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total_facilities AS NUMERIC) AS total_facilities,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__stations_by_mode_and_age
