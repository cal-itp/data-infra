WITH int_ntd__capital_expenditures_time_series_other AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_other') }}
),

fct_capital_expenditures_time_series_other AS (
    SELECT *
    FROM int_ntd__capital_expenditures_time_series_other
)

SELECT
    agency_name,
    agency_status,
    census_year,
    city,
    last_report_year,
    legacy_ntd_id,
    mode,
    ntd_id,
    reporter_type,
    reporting_module,
    state,
    uace_code,
    uza_area_sq_miles,
    uza_name,
    uza_population,
    year,
    other,
    _2023_mode_status,
    dt,
    execution_ts
FROM fct_capital_expenditures_time_series_other
