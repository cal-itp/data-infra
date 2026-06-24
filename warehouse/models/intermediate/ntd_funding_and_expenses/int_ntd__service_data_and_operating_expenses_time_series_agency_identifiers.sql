{{ config(materialized='table') }}

WITH int_upt AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_upt') }}
),

int_total AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_total') }}
),

upt_agency_identifiers AS (
    SELECT
        key,
        agency_status,
        census_year,
        last_report_year,
        mode_status,
        reporter_type,
        reporting_module,
        uace_code,
        uza_area_sq_miles,
        primary_uza_name,
        uza_population,
        agency_name AS source_agency,
        city AS source_city,
        state AS source_state,

    FROM int_upt
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
),

opexp_agency_identifiers AS (
    SELECT
        key,
        agency_status,
        census_year,
        last_report_year,
        mode_status,
        reporter_type,
        reporting_module,
        uace_code,
        uza_area_sq_miles,
        primary_uza_name,
        uza_population,
        agency_name AS source_agency,
        city AS source_city,
        state AS source_state,

    FROM int_total
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
),

agency_identifiers AS (
    SELECT * FROM upt_agency_identifiers
    UNION DISTINCT
    SELECT * FROM opexp_agency_identifiers
)
SELECT * FROM agency_identifiers
