WITH int_ntd__operating_and_capital_funding_time_series_capital_state AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_capital_state') }}
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

fct_operating_and_capital_funding_time_series_capital_state AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['int.ntd_id', 'int.year', 'int.legacy_ntd_id']) }} AS key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

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
        int.capital_state,
        int._2023_status,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM int_ntd__operating_and_capital_funding_time_series_capital_state AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
)

SELECT * FROM fct_operating_and_capital_funding_time_series_capital_state
