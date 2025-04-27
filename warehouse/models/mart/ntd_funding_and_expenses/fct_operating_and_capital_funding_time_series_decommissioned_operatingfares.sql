WITH intermediate_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT *
    FROM {{ ref('int_ntd__operating_and_capital_funding_time_series_decommissioned_operatingfares') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
    SELECT
        int.ntd_id,
        int.city,
        int.state,
        int.agency_name,
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

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM intermediate_operating_and_capital_funding_time_series_decommissioned_operatingfares AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_operating_and_capital_funding_time_series_decommissioned_operatingfares
