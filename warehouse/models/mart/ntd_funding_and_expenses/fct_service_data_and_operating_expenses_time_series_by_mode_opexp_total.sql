WITH int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_total AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_total') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_service_data_and_operating_expenses_time_series_by_mode_opexp_total AS (
    SELECT
        int.agency_name,
        int.agency_status,
        int.census_year,
        int.city,
        int.last_report_year,
        int.legacy_ntd_id,
        int.mode,
        int.mode_status,
        int.ntd_id,
        int.reporter_type,
        int.reporting_module,
        int.service,
        int.state,
        int.uace_code,
        int.uza_area_sq_miles,
        int.primary_uza_name,
        int.uza_population,
        int.year,
        int.opexp_total,
        int._2023_mode_status,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_total AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_service_data_and_operating_expenses_time_series_by_mode_opexp_total
