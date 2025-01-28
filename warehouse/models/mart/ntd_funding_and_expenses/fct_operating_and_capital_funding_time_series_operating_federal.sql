WITH staging_operating_and_capital_funding_time_series_operating_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__operating_federal') }}
),

fct_operating_and_capital_funding_time_series_operating_federal AS (
    SELECT *
    FROM staging_operating_and_capital_funding_time_series_operating_federal
)

SELECT
    _1991,
    _1992,
    _1993,
    _1994,
    _1995,
    _1996,
    _1997,
    _1998,
    _1999,
    _2000,
    _2001,
    _2002,
    _2003,
    _2004,
    _2005,
    _2006,
    _2007,
    _2008,
    _2009,
    _2010,
    _2011,
    _2012,
    _2013,
    _2014,
    _2015,
    _2016,
    _2017,
    _2018,
    _2019,
    _2020,
    _2021,
    _2022,
    _2023,
    _2023_status,
    agency_name,
    agency_status,
    census_year,
    city,
    last_report_year,
    legacy_ntd_id,
    ntd_id,
    primary_uza_name,
    reporter_type,
    reporting_module,
    state,
    uace_code,
    uza_area_sq_miles,
    uza_population,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_operating_federal
