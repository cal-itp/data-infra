{{ config(materialized='table') }}

WITH int_upt AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_upt') }}
),

int_vrh AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_vrh') }}
),

int_vrm AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_vrm') }}
),

int_voms AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_voms') }}
),

int_pmt AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_pmt') }}
),

int_drm AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_drm') }}
),

-- funding
int_vo AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_vo') }}
),

int_vm AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_vm') }}
),

int_ga AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_ga') }}
),

int_nvm AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm') }}
),

int_total AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_total') }}
),

int_fares AS (
    SELECT *
    FROM {{ ref('int_ntd__service_data_and_operating_expenses_time_series_by_mode_fares') }}
),

service_data_and_operating_expenses_time_series_by_mode AS (
    SELECT
        COALESCE(int_upt.key, int_vrh.key, int_vrm.key, int_voms.key, int_pmt.key, int_drm.key,
            int_vo.key, int_vm.key, int_nvm.key, int_ga.key, int_total.key, int_fares.key) AS key,
        COALESCE(int_upt.ntd_id, int_vrh.ntd_id, int_vrm.ntd_id, int_voms.ntd_id, int_pmt.ntd_id, int_drm.ntd_id,
            int_vo.ntd_id, int_vm.ntd_id, int_nvm.ntd_id, int_ga.ntd_id, int_total.ntd_id, int_fares.ntd_id) AS ntd_id,
        COALESCE(int_upt.mode, int_vrh.mode, int_vrm.mode, int_voms.mode, int_pmt.mode, int_drm.mode,
            int_vo.mode, int_vm.mode, int_nvm.mode, int_ga.mode, int_total.mode, int_fares.mode) AS mode,
        COALESCE(int_upt.year, int_vrh.year, int_vrm.year, int_voms.year, int_pmt.year, int_drm.year,
            int_vo.year, int_vm.year, int_nvm.year, int_ga.year, int_total.year, int_fares.year) AS year,
        COALESCE(int_upt.type_of_service, int_vrh.type_of_service, int_vrm.type_of_service,
            int_voms.type_of_service, int_pmt.type_of_service, int_drm.type_of_service,
            int_vo.type_of_service, int_vm.type_of_service, int_nvm.type_of_service, int_ga.type_of_service,
            int_total.type_of_service, int_fares.type_of_service) AS type_of_service,

        int_upt.upt AS unlinked_passenger_trips,
        int_vrh.vrh AS vehicle_revenue_hours,
        int_vrm.vrm AS vehicle_revenue_miles,
        int_voms.voms AS vehicles_operated_in_maxiumum_service,
        int_pmt.pmt AS passenger_miles_traveled,
        int_drm.drm AS direction_route_miles,

        int_vo.opexp_vo AS operating_expenses_vehicle_operations,
        int_vm.opexp_vm AS operating_expenses_vehicle_maintenance,
        int_nvm.opexp_nvm AS operating_expenses_nonvehicle_maintenance,
        int_ga.opexp_ga AS operating_expenses_general_administration,
        int_total.opexp_total AS operating_expenses_total,
        int_fares.fares AS fare_revenue,

        -- check these
        SAFE_DIVIDE(int_total.opexp_total, int_vrh.vrh) AS opex_per_vrh,
        SAFE_DIVIDE(int_total.opexp_total, int_vrm.vrm) AS opex_per_vrm,
        SAFE_DIVIDE(int_total.opexp_total, int_upt.upt) AS opex_per_upt,
        SAFE_DIVIDE(int_upt.upt, int_vrh.vrh) AS upt_per_vrh,
        SAFE_DIVIDE(int_upt.upt, int_vrm.vrm) AS upt_per_vrm,
        SAFE_DIVIDE(int_fares.fares, int_total.opexp_total) AS farebox_recovery_ratio,

        -- same number of rows for all Excel sheets, left join is fine.
        -- use upt to bring in agency indentifiers
        int_upt.agency_status,
        int_upt.census_year,
        int_upt.last_report_year,
        int_upt.mode_status,
        int_upt.reporter_type,
        int_upt.reporting_module,
        int_upt.uace_code,
        int_upt.uza_area_sq_miles,
        int_upt.primary_uza_name,
        int_upt.uza_population,
        int_upt.source_agency,
        int_upt.source_city,
        int_upt.source_state,
        int_upt.dt,
        int_upt.execution_ts,

    FROM int_upt
    LEFT JOIN int_vrh USING (key)
    LEFT JOIN int_vrm USING (key)
    LEFT JOIN int_voms USING (key)
    LEFT JOIN int_pmt USING (key)
    LEFT JOIN int_drm USING (key)
    LEFT JOIN int_vo USING (key)
    LEFT JOIN int_vm USING (key)
    LEFT JOIN int_nvm USING (key)
    LEFT JOIN int_ga USING (key)
    LEFT JOIN int_total USING (key)
    LEFT JOIN int_fares USING (key)
),

fct_service_data_and_operating_expenses_time_series_by_mode AS (
    SELECT
        *,
        LAG(unlinked_passenger_trips) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY YEAR) AS upt_prior_year,
        unlinked_passenger_trips - LAG(unlinked_passenger_trips) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY YEAR) AS upt_change_1yr,
        ROUND(SAFE_DIVIDE(
          (unlinked_passenger_trips - LAG(unlinked_passenger_trips) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY YEAR)),
          LAG(unlinked_passenger_trips) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY YEAR)
        ), 4) AS upt_pct_change_1yr,

        {{ generate_ntd_mode_full_name('mode') }} AS mode_full_name,
        {{ generate_ntd_type_of_service_full_name('type_of_service') }} AS type_of_service_full_name,
        {{ generate_ntd_mode_service_type('mode') }} AS service_type,

    FROM service_data_and_operating_expenses_time_series_by_mode
    WHERE key NOT IN ('e41f3812655066d28ec4bbc851545517','f5f160d19e3753e3a99d9ad55b4f2210','7d3e30725b3fa42c6d1722308f9cc855',
        'da108425cb2696446aa1017bca72340f','a31019318eddb35b747ab79470e10017','98692053a5a16aae8ef8e2579f19b8a3',
        'd6809f84a9d19808f8b1f013fc1cd537','c3ae0b0299c10ffa25e1193404762136','564993fcc3a920cc0800005f3af9fd73',
        '73f01d2aa1c268ec1dafbcf1fdaa84fc','5b13563073a95faa05c9da4f77c0b3a8','0fab2ef186a2a74edc98d16427d4d61a'
    )
)

SELECT * FROM fct_service_data_and_operating_expenses_time_series_by_mode
