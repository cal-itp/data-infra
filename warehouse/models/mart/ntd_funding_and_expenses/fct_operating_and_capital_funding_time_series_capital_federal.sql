WITH int_ntd__operating_and_capital_funding_time_series_capital_federal AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_federal') }}
),

fct_operating_and_capital_funding_time_series_capital_federal AS (
    SELECT *
    FROM int_ntd__operating_and_capital_funding_time_series_capital_federal
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
    capital_federal,
    _2023_status,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_capital_federal
