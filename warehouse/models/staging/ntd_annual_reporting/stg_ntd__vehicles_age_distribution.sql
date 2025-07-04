WITH external_vehicles_age_distribution AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__vehicles_age_distribution') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_vehicles_age_distribution
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__vehicles_age_distribution AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year', 'vehicle_type']) }} AS key,
        SAFE_CAST(_0 AS NUMERIC) AS _0,
        SAFE_CAST(_1 AS NUMERIC) AS _1,
        SAFE_CAST(_10 AS NUMERIC) AS _10,
        SAFE_CAST(_11 AS NUMERIC) AS _11,
        SAFE_CAST(_12 AS NUMERIC) AS _12,
        SAFE_CAST(_13_15 AS NUMERIC) AS _13_15,
        SAFE_CAST(_16_20 AS NUMERIC) AS _16_20,
        SAFE_CAST(_2 AS NUMERIC) AS _2,
        SAFE_CAST(_21_25 AS NUMERIC) AS _21_25,
        SAFE_CAST(_26_30 AS NUMERIC) AS _26_30,
        SAFE_CAST(_3 AS NUMERIC) AS _3,
        SAFE_CAST(_31_60 AS NUMERIC) AS _31_60,
        SAFE_CAST(_4 AS NUMERIC) AS _4,
        SAFE_CAST(_5 AS NUMERIC) AS _5,
        SAFE_CAST(_6 AS NUMERIC) AS _6,
        SAFE_CAST(_60 AS NUMERIC) AS _60,
        SAFE_CAST(_7 AS NUMERIC) AS _7,
        SAFE_CAST(_8 AS NUMERIC) AS _8,
        SAFE_CAST(_9 AS NUMERIC) AS _9,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        SAFE_CAST(average_age_of_fleet_in_years AS NUMERIC) AS average_age_of_fleet_in_years,
        {{ trim_make_empty_string_null('average_lifetime_miles_per') }} AS average_lifetime_miles_per,
        {{ trim_make_empty_string_null('city') }} AS city,
        {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        CAST(SAFE_CAST(report_year AS FLOAT64) AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(total_vehicles AS NUMERIC) AS total_vehicles,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        {{ trim_make_empty_string_null('vehicle_type') }} AS vehicle_type,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__vehicles_age_distribution
