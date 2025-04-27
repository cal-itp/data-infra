WITH intermediate_asset_inventory_time_series_avg_standing_capacity AS (
    SELECT *
    FROM {{ ref('int_ntd__asset_inventory_time_series_avg_standing_capacity') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_asset_inventory_time_series_avg_standing_capacity AS (
    SELECT
        int.year,
        int.total,
        int.state,
        int.uza_area_sq_miles,
        int.ntd_id,
        int.legacy_ntd_id,
        int.uace_code,
        int.last_report_year,
        int.mode_status,
        int.service,
        int._2023_mode_status,
        int.agency_status,
        int.uza_population,
        int.mode,
        int.uza_name,
        int.city,
        int.census_year,
        int.reporting_module,
        int.reporter_type,
        int.agency_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        int.dt,
        int.execution_ts
    FROM intermediate_asset_inventory_time_series_avg_standing_capacity AS int
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_asset_inventory_time_series_avg_standing_capacity
