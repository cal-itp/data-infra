WITH int_ntd__operating_and_capital_funding_time_series_operating_local AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_local') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_and_capital_funding_time_series_operating_local AS (
    SELECT
        int.agency_name,
        int.ntd_id,
        int.year,
        int.city,
        int.state,
        int.agency_status,
        int.census_year,
        int.last_report_year,
        int.legacy_ntd_id,
        int.reporter_type,
        int.reporting_module,
        int.uace_code,
        int.uza_area_sq_miles,
        int.primary_uza_name,
        int.uza_population,
        int.operating_local,
        int._2023_status,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM int_ntd__operating_and_capital_funding_time_series_operating_local AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_and_capital_funding_time_series_operating_local
