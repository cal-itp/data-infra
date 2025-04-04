WITH staging_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__decommissioned_operatingfares') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_operating_and_capital_funding_time_series_decommissioned_operatingfares.*,
        current_dim_organizations.caltrans_district
    FROM staging_operating_and_capital_funding_time_series_decommissioned_operatingfares
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT *
    FROM enrich_with_caltrans_district
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
    caltrans_district,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_decommissioned_operatingfares
