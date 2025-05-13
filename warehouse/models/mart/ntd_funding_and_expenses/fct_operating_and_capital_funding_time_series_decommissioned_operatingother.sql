WITH intermediate_operating_and_capital_funding_time_series_decommissioned_operatingother AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_decommissioned_operatingother') }}
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

fct_operating_and_capital_funding_time_series_decommissioned_operatingother AS (
    SELECT
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int._2017_status,
        int.agency_status,
        int.uza_population,
        int.uza_area_sq_miles,
        int.uza,
        int.primary_uza_name,
        int.legacy_ntd_id,
        int.census_year,
        int.reporting_module,
        int.last_report_year,
        int.reporter_type,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM intermediate_operating_and_capital_funding_time_series_decommissioned_operatingother AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
)

SELECT * FROM fct_operating_and_capital_funding_time_series_decommissioned_operatingother
