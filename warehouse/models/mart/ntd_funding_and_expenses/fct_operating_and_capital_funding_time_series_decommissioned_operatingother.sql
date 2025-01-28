WITH staging_operating_and_capital_funding_time_series_decommissioned_operatingother AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__decommissioned_operatingother') }}
),

fct_operating_and_capital_funding_time_series_decommissioned_operatingother AS (
    SELECT *
    FROM staging_operating_and_capital_funding_time_series_decommissioned_operatingother
)

SELECT
    _2017,
    _2016,
    _2014,
    _2012,
    _2010,
    _2009,
    _2008,
    _2007,
    _2005,
    _2013,
    _2002,
    _2006,
    _2000,
    _2004,
    _2003,
    _1999,
    _1997,
    _2011,
    _1995,
    _1994,
    _2017_status,
    agency_status,
    _1992,
    uza_population,
    uza_area_sq_miles,
    _2001,
    _1996,
    _1991,
    uza,
    city,
    _1998,
    _2015,
    primary_uza_name,
    legacy_ntd_id,
    census_year,
    _1993,
    reporting_module,
    last_report_year,
    state,
    reporter_type,
    agency_name,
    ntd_id,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_decommissioned_operatingother
