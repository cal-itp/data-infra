WITH staging_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__decommissioned_operatingfares') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT
        stg._2017,
        stg._2016,
        stg._2014,
        stg._2012,
        stg._2010,
        stg._2009,
        stg._2008,
        stg._2007,
        stg._2005,
        stg._2013,
        stg._2002,
        stg._2006,
        stg._2000,
        stg._2004,
        stg._2003,
        stg._1999,
        stg._1997,
        stg._2011,
        stg._1995,
        stg._1994,
        stg._2017_status,
        stg.agency_status,
        stg._1992,
        stg.uza_population,
        stg.uza_area_sq_miles,
        stg._2001,
        stg._1996,
        stg._1991,
        stg.uza,
        stg.city,
        stg._1998,
        stg._2015,
        stg.primary_uza_name,
        stg.legacy_ntd_id,
        stg.census_year,
        stg._1993,
        stg.reporting_module,
        stg.last_report_year,
        stg.state,
        stg.reporter_type,
        stg.agency_name,
        stg.ntd_id,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_operating_and_capital_funding_time_series_decommissioned_operatingfares AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_and_capital_funding_time_series_decommissioned_operatingfares
