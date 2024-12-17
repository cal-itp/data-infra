WITH external_track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__track_and_roadway_guideway_age_distribution') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_track_and_roadway_guideway_age_distribution
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__track_and_roadway_guideway_age_distribution AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(_1940s AS NUMERIC) AS _1940s,
    {{ trim_make_empty_string_null('_1940s_q') }} AS _1940s_q,
    SAFE_CAST(_1950s AS NUMERIC) AS _1950s,
    {{ trim_make_empty_string_null('_1950s_q') }} AS _1950s_q,
    SAFE_CAST(_1960s AS NUMERIC) AS _1960s,
    {{ trim_make_empty_string_null('_1960s_q') }} AS _1960s_q,
    SAFE_CAST(_1970s AS NUMERIC) AS _1970s,
    {{ trim_make_empty_string_null('_1970s_q') }} AS _1970s_q,
    SAFE_CAST(_1980s AS NUMERIC) AS _1980s,
    {{ trim_make_empty_string_null('_1980s_q') }} AS _1980s_q,
    SAFE_CAST(_1990s AS NUMERIC) AS _1990s,
    {{ trim_make_empty_string_null('_1990s_q') }} AS _1990s_q,
    SAFE_CAST(_2000s AS NUMERIC) AS _2000s,
    {{ trim_make_empty_string_null('_2000s_q') }} AS _2000s_q,
    SAFE_CAST(_2010s AS NUMERIC) AS _2010s,
    {{ trim_make_empty_string_null('_2010s_q') }} AS _2010s_q,
    SAFE_CAST(_2020s AS NUMERIC) AS _2020s,
    {{ trim_make_empty_string_null('_2020s_q') }} AS _2020s_q,
    {{ trim_make_empty_string_null('agency') }} AS agency,
    SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
    {{ trim_make_empty_string_null('city') }} AS city,
    {{ trim_make_empty_string_null('guideway_element') }} AS guideway_element,
    {{ trim_make_empty_string_null('mode') }} AS mode,
    {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
    SAFE_CAST(pre1940s AS NUMERIC) AS pre1940s,
    {{ trim_make_empty_string_null('pre1940s_q') }} AS pre1940s_q,
    SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
    {{ trim_make_empty_string_null('state') }} AS state,
    {{ trim_make_empty_string_null('type_of_service') }} AS type_of_service,
    {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
    {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
    dt,
    execution_ts
FROM stg_ntd__track_and_roadway_guideway_age_distribution
