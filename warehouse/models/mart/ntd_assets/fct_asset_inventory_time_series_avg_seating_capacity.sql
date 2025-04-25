WITH staging_asset_inventory_time_series_avg_seating_capacity AS (
    SELECT *
    FROM {{ ref('stg_ntd__asset_inventory_time_series__avg_seating_capacity') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_asset_inventory_time_series_avg_seating_capacity AS (
    SELECT
        stg.state,
        stg.uza_area_sq_miles,
        stg.ntd_id,
        stg.legacy_ntd_id,
        stg.uace_code,
        stg.last_report_year,
        stg.mode_status,
        stg.service,
        stg._2023_mode_status,
        stg.agency_status,
        stg.uza_population,
        stg.mode,
        stg.uza_name,
        stg.city,
        stg.census_year,
        stg.reporting_module,
        stg.reporter_type,
        stg.agency_name,
        stg._2021,
        stg._2023,
        stg._1995,
        stg._2015,
        stg._2019,
        stg._2014,
        stg._2012,
        stg._2008,
        stg._2007,
        stg._2013,
        stg._2002,
        stg._2006,
        stg._2000,
        stg._2004,
        stg._2003,
        stg._1998,
        stg._2022,
        stg._1999,
        stg._1997,
        stg._2011,
        stg._2001,
        stg._1996,
        stg._2020,
        stg._2005,
        stg._2017,
        stg._1994,
        stg._1992,
        stg._2010,
        stg._2009,
        stg._2016,
        stg._2018,
        stg._1993,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_asset_inventory_time_series_avg_seating_capacity AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_asset_inventory_time_series_avg_seating_capacity
