WITH int_ntd__operating_and_capital_funding_time_series_operating_federal AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_federal') }}
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
        int_ntd__operating_and_capital_funding_time_series_operating_federal.*,
        current_dim_organizations.caltrans_district
    FROM int_ntd__operating_and_capital_funding_time_series_operating_federal
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_operating_and_capital_funding_time_series_operating_federal AS (
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
    ntd_id,
    reporter_type,
    reporting_module,
    state,
    uace_code,
    uza_area_sq_miles,
    primary_uza_name,
    uza_population,
    year,
    operating_federal,
    _2023_status,
    caltrans_district,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_operating_federal
