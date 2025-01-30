WITH int_ntd__operating_and_capital_funding_time_series_operating_total AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_total') }}
),

fct_operating_and_capital_funding_time_series_operating_total AS (
    SELECT *
    FROM int_ntd__operating_and_capital_funding_time_series_operating_total
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
    operating_total,
    _2023_status,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_operating_total
