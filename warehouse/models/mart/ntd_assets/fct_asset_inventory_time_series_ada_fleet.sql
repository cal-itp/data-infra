WITH staging_asset_inventory_time_series_ada_fleet AS (
    SELECT *
    FROM {{ ref('int_ntd__asset_inventory_time_series_ada_fleet') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_asset_inventory_time_series_ada_fleet AS (
    SELECT
        stg.year,
        stg.total,
        stg.state,
        stg.uza_area_sq_miles,
        stg.ntd_id,
        stg.legacy_ntd_id,
        stg.uace_code,
        stg.last_report_year,
        stg.mode_status,
        stg.service,
        stg._2023_mode_status,
        stg.agency_status,
        stg.uza_population,
        stg.mode,
        stg.uza_name,
        stg.city,
        stg.census_year,
        stg.reporting_module,
        stg.reporter_type,
        stg.agency_name,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_asset_inventory_time_series_ada_fleet AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_asset_inventory_time_series_ada_fleet
