WITH int_ntd__operating_and_capital_funding_time_series_operating_state AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_state') }}
),

fct_operating_and_capital_funding_time_series_operating_state AS (
    SELECT *
    FROM int_ntd__operating_and_capital_funding_time_series_operating_state
)

SELECT
    agency_name,
    agency_status,
    census_year,
    city,
    last_report_year,
    legacy_ntd_id,
    ntd_id,
    reporter_type,
    reporting_module,
    state,
    uace_code,
    uza_area_sq_miles,
    primary_uza_name,
    uza_population,
    year,
    operating_state,
    _2023_status,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_operating_state
