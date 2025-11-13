WITH source AS (
    SELECT *
    FROM {{ source('external_ntd__funding_and_expenses', 'historical__service_data_and_operating_expenses_time_series_by_mode__pmt') }}
),

get_latest_extract AS(
    SELECT *
    FROM source
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__service_data_and_operating_expenses_time_series_by_mode__pmt AS (
    SELECT
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('CAST(legacy_ntd_id AS STRING)') }} AS legacy_ntd_id,
        {{ trim_make_empty_string_null('agency_name') }} AS agency_name,
        {{ trim_make_empty_string_null('agency_status') }} AS agency_status,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('reporting_module') }} AS reporting_module,
        {{ trim_make_empty_string_null('service') }} AS service,
        {{ trim_make_empty_string_null('mode') }} AS mode,
        {{ trim_make_empty_string_null('mode_status') }} AS mode_status,
        SAFE_CAST(last_report_year AS INT64) AS last_report_year,
        {{ trim_make_empty_string_null('city') }} AS city,
        {{ trim_make_empty_string_null('state') }} AS state,
        {{ trim_make_empty_string_null('primary_uza_name') }} AS primary_uza_name,
        SAFE_CAST(uace_code AS INT64) AS uace_code,
        SAFE_CAST(census_year AS INT64) AS census_year,
        SAFE_CAST(uza_area_sq_miles AS FLOAT64) AS uza_area_sq_miles,
        SAFE_CAST(uza_population AS INT64) AS uza_population,
        SAFE_CAST(_2015 AS FLOAT64) AS _2015,
        SAFE_CAST(_2016 AS FLOAT64) AS _2016,
        SAFE_CAST(_2017 AS FLOAT64) AS _2017,
        SAFE_CAST(_2018 AS FLOAT64) AS _2018,
        SAFE_CAST(_2019 AS FLOAT64) AS _2019,
        SAFE_CAST(_2020 AS FLOAT64) AS _2020,
        SAFE_CAST(_2021 AS FLOAT64) AS _2021,
        SAFE_CAST(_2022 AS FLOAT64) AS _2022,
        SAFE_CAST(_2023 AS FLOAT64) AS _2023,
        SAFE_CAST(_2024 AS FLOAT64) AS _2024,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__service_data_and_operating_expenses_time_series_by_mode__pmt
