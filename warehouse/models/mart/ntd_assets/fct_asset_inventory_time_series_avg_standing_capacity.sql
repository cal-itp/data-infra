WITH intermediate_asset_inventory_time_series_avg_standing_capacity AS (
    SELECT *
    FROM {{ ref('int_ntd__asset_inventory_time_series_avg_standing_capacity') }}
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

fct_asset_inventory_time_series_avg_standing_capacity AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['int.ntd_id', 'int.year', 'int.legacy_ntd_id', 'int.mode', 'int.service']) }} AS key,
        int.ntd_id,
        int.year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        int.legacy_ntd_id,
        int.mode,
        int.service,
        int.total,
        int.uza_area_sq_miles,
        int.uace_code,
        int.last_report_year,
        int.mode_status,
        int._2023_mode_status,
        int.agency_status,
        int.uza_population,
        int.uza_name,
        int.census_year,
        int.reporting_module,
        int.reporter_type,
        int.agency_name AS source_agency,
        int.city AS source_city,
        int.state AS source_state,
        int.dt,
        int.execution_ts
    FROM intermediate_asset_inventory_time_series_avg_standing_capacity AS int
    LEFT JOIN dim_agency_information AS agency
        ON int.ntd_id = agency.ntd_id
            AND int.year = agency.year
)

SELECT * FROM fct_asset_inventory_time_series_avg_standing_capacity
