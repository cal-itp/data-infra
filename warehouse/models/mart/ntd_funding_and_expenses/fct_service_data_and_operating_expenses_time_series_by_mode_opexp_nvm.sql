WITH int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm') }}
),

fct_service_data_and_operating_expenses_time_series_by_mode_opexp_nvm AS (
    SELECT *
    FROM int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm
)

SELECT
    agency_name,
    agency_status,
    census_year,
    city,
    last_report_year,
    legacy_ntd_id,
    mode,
    mode_status,
    ntd_id,
    reporter_type,
    reporting_module,
    service,
    state,
    uace_code,
    uza_area_sq_miles,
    primary_uza_name,
    uza_population,
    year,
    opexp_nvm,
    _2023_mode_status,
    dt,
    execution_ts
FROM fct_service_data_and_operating_expenses_time_series_by_mode_opexp_nvm
