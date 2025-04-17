WITH int_ntd__capital_expenditures_time_series_rolling_stock AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_rolling_stock') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_capital_expenditures_time_series_rolling_stock AS (
    SELECT
        int.agency_name,
        int.agency_status,
        int.census_year,
        int.city,
        int.last_report_year,
        int.legacy_ntd_id,
        int.mode,
        int.ntd_id,
        int.reporter_type,
        int.reporting_module,
        int.state,
        int.uace_code,
        int.uza_area_sq_miles,
        int.uza_name,
        int.uza_population,
        int.year,
        int.rolling_stock,
        int._2023_mode_status,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM int_ntd__capital_expenditures_time_series_rolling_stock AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_capital_expenditures_time_series_rolling_stock
