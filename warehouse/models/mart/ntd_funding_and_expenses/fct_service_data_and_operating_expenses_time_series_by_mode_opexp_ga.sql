WITH int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_ga AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_ga') }}
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
        int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_ga.*,
        current_dim_organizations.caltrans_district
    FROM int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_ga
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_service_data_and_operating_expenses_time_series_by_mode_opexp_ga AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    agency_name,
    agency_status,
    census_year,
    city,
    last_report_year,
    legacy_ntd_id,
    mode,
    mode_status,
    ntd_id,
    reporter_type,
    reporting_module,
    service,
    state,
    uace_code,
    uza_area_sq_miles,
    primary_uza_name,
    uza_population,
    year,
    opexp_ga,
    _2023_mode_status,
    caltrans_district,
    dt,
    execution_ts
FROM fct_service_data_and_operating_expenses_time_series_by_mode_opexp_ga
