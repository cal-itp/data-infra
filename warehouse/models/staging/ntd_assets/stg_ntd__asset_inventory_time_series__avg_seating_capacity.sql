WITH external_avg_seating_capacity AS (
    SELECT *
    FROM {{ source('external_ntd__assets', 'historical__asset_inventory_time_series__avg_seating_capacity') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_avg_seating_capacity
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__asset_inventory_time_series__avg_seating_capacity AS (
    SELECT
        {{ trim_make_empty_string_null('state') }} AS state,
        SAFE_CAST(uza_area_sq_miles AS NUMERIC) AS uza_area_sq_miles,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('legacy_ntd_id') }} AS legacy_ntd_id,
        SAFE_CAST(uace_code AS INTEGER) AS uace_code,
        SAFE_CAST(last_report_year AS INTEGER) AS last_report_year,
        {{ trim_make_empty_string_null('mode_status') }} AS mode_status,
        {{ trim_make_empty_string_null('service') }} AS service,
        {{ trim_make_empty_string_null('_2023_mode_status') }} AS _2023_mode_status,
        {{ trim_make_empty_string_null('agency_status') }} AS agency_status,
        SAFE_CAST(uza_population AS INTEGER) AS uza_population,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(census_year AS INTEGER) AS census_year,
        {{ trim_make_empty_string_null('reporting_module') }} AS reporting_module,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
        SAFE_CAST(_2021 AS NUMERIC) AS _2021,
        SAFE_CAST(_2023 AS NUMERIC) AS _2023,
        SAFE_CAST(_1995 AS NUMERIC) AS _1995,
        SAFE_CAST(_2015 AS NUMERIC) AS _2015,
        SAFE_CAST(_2019 AS NUMERIC) AS _2019,
        SAFE_CAST(_2014 AS NUMERIC) AS _2014,
        SAFE_CAST(_2012 AS NUMERIC) AS _2012,
        SAFE_CAST(_2008 AS NUMERIC) AS _2008,
        SAFE_CAST(_2007 AS NUMERIC) AS _2007,
        SAFE_CAST(_2013 AS NUMERIC) AS _2013,
        SAFE_CAST(_2002 AS NUMERIC) AS _2002,
        SAFE_CAST(_2006 AS NUMERIC) AS _2006,
        SAFE_CAST(_2000 AS NUMERIC) AS _2000,
        SAFE_CAST(_2004 AS NUMERIC) AS _2004,
        SAFE_CAST(_1998 AS NUMERIC) AS _1998,
        SAFE_CAST(_2003 AS NUMERIC) AS _2003,
        SAFE_CAST(_2022 AS NUMERIC) AS _2022,
        SAFE_CAST(_1999 AS NUMERIC) AS _1999,
        SAFE_CAST(_1997 AS NUMERIC) AS _1997,
        SAFE_CAST(_2011 AS NUMERIC) AS _2011,
        SAFE_CAST(_2001 AS NUMERIC) AS _2001,
        SAFE_CAST(_1996 AS NUMERIC) AS _1996,
        SAFE_CAST(_2020 AS NUMERIC) AS _2020,
        SAFE_CAST(_2005 AS NUMERIC) AS _2005,
        SAFE_CAST(_2017 AS NUMERIC) AS _2017,
        SAFE_CAST(_1994 AS NUMERIC) AS _1994,
        SAFE_CAST(_1992 AS NUMERIC) AS _1992,
        SAFE_CAST(_2010 AS NUMERIC) AS _2010,
        SAFE_CAST(_2009 AS NUMERIC) AS _2009,
        SAFE_CAST(_2016 AS NUMERIC) AS _2016,
        SAFE_CAST(_2018 AS NUMERIC) AS _2018,
        SAFE_CAST(_1993 AS NUMERIC) AS _1993,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__asset_inventory_time_series__avg_seating_capacity
