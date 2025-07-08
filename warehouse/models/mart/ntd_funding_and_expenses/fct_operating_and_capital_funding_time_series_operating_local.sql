WITH int_ntd__operating_and_capital_funding_time_series_operating_local AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_operating_local') }}
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_operating_and_capital_funding_time_series_operating_local AS (
    SELECT
        int.key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.legacy_ntd_id,
        int.agency_status,
        int.census_year,
        int.last_report_year,
        int.reporter_type,
        int.reporting_module,
        int.uace_code,
        int.uza_area_sq_miles,
        int.primary_uza_name,
        int.uza_population,
        int.operating_local,
        int._2023_status,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM int_ntd__operating_and_capital_funding_time_series_operating_local AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE int.key NOT IN ('4c39c378621ca926c1e98efc929a64f9','ceee48d5b549eacd30c16bc7af1ec79d','21f4adad5adcd91c37292b036d47370d',
        '7417b3a1931fc284be99824925f55d55')
)

SELECT * FROM fct_operating_and_capital_funding_time_series_operating_local
