WITH source AS (
    SELECT *
    FROM {{ source('external_ntd__funding_and_expenses', 'historical__service_data_and_operating_expenses_time_series_by_mode__vrh') }}
),

get_latest_extract AS(
    SELECT *
    FROM source
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__service_data_and_operating_expenses_time_series_by_mode__vrh AS (
    SELECT
        SAFE_CAST(_2021 AS FLOAT64) AS _2021,
        SAFE_CAST(_2020 AS FLOAT64) AS _2020,
        SAFE_CAST(_2016 AS FLOAT64) AS _2016,
        SAFE_CAST(_2019 AS FLOAT64) AS _2019,
        SAFE_CAST(_2014 AS FLOAT64) AS _2014,
        SAFE_CAST(_2012 AS FLOAT64) AS _2012,
        SAFE_CAST(_2008 AS FLOAT64) AS _2008,
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(uza_area_sq_miles AS FLOAT64) AS uza_area_sq_miles,
        SAFE_CAST(_2007 AS FLOAT64) AS _2007,
        SAFE_CAST(_2013 AS FLOAT64) AS _2013,
        SAFE_CAST(_2002 AS FLOAT64) AS _2002,
        SAFE_CAST(_2006 AS FLOAT64) AS _2006,
        SAFE_CAST(_2000 AS FLOAT64) AS _2000,
        {{ trim_make_empty_string_null('CAST(legacy_ntd_id AS STRING)') }} AS legacy_ntd_id,
        SAFE_CAST(uace_code AS INT64) AS uace_code,
        SAFE_CAST(_2004 AS FLOAT64) AS _2004,
        SAFE_CAST(_1998 AS FLOAT64) AS _1998,
        SAFE_CAST(_2003 AS FLOAT64) AS _2003,
        SAFE_CAST(_2022 AS FLOAT64) AS _2022,
        SAFE_CAST(_1999 AS FLOAT64) AS _1999,
        SAFE_CAST(last_report_year AS INT64) AS last_report_year,
        SAFE_CAST(_1997 AS FLOAT64) AS _1997,
        SAFE_CAST(_2001 AS FLOAT64) AS _2001,
        SAFE_CAST(_1996 AS FLOAT64) AS _1996,
        SAFE_CAST(_2011 AS FLOAT64) AS _2011,
        SAFE_CAST(_2023 AS FLOAT64) AS _2023,
        SAFE_CAST(_2015 AS FLOAT64) AS _2015,
        SAFE_CAST(_1995 AS FLOAT64) AS _1995,
        {{ trim_make_empty_string_null('primary_uza_name') }} AS primary_uza_name,
        SAFE_CAST(_2005 AS FLOAT64) AS _2005,
        {{ trim_make_empty_string_null('mode_status') }} AS mode_status,
        SAFE_CAST(_2017 AS FLOAT64) AS _2017,
        {{ trim_make_empty_string_null('service') }} AS service,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        SAFE_CAST(_1994 AS FLOAT64) AS _1994,
        {{ trim_make_empty_string_null('_2023_mode_status') }} AS _2023_mode_status,
        {{ trim_make_empty_string_null('agency_status') }} AS agency_status,
        SAFE_CAST(_1992 AS FLOAT64) AS _1992,
        SAFE_CAST(uza_population AS INT64) AS uza_population,
        SAFE_CAST(_2010 AS FLOAT64) AS _2010,
        SAFE_CAST(_2009 AS FLOAT64) AS _2009,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(_1991 AS FLOAT64) AS _1991,
        SAFE_CAST(_2018 AS FLOAT64) AS _2018,
        SAFE_CAST(census_year AS INT64) AS census_year,
        SAFE_CAST(_1993 AS FLOAT64) AS _1993,
        {{ trim_make_empty_string_null('reporting_module') }} AS reporting_module,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__service_data_and_operating_expenses_time_series_by_mode__vrh
