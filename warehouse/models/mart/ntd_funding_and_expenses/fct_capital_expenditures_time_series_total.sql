WITH int_ntd__capital_expenditures_time_series_total AS (
    SELECT *
    FROM {{ ref('int_ntd__capital_expenditures_time_series_total') }}
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

fct_capital_expenditures_time_series_total AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['int.ntd_id', 'int.year', 'int.legacy_ntd_id', 'int.mode']) }} AS key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.legacy_ntd_id,
        int.mode,
        int.agency_status,
        int.census_year,
        int.last_report_year,
        int.reporter_type,
        int.reporting_module,
        int.uace_code,
        int.uza_area_sq_miles,
        int.uza_name,
        int.uza_population,
        int.total,
        int._2023_mode_status,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM int_ntd__capital_expenditures_time_series_total AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
)

SELECT * FROM fct_capital_expenditures_time_series_total
