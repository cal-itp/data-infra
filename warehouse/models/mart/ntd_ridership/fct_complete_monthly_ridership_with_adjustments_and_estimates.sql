{{ config(materialized="table") }}

WITH staging_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.mode', 'stg.type_of_service', 'month_first_day']) }} as key,

        stg.ntd_id,
        stg.agency,

        stg.date,
        stg.month,
        stg.year,
        stg.month_first_day,
        stg.type_of_service,
        stg.mode,

        {{ generate_ntd_mode_full_name('mode') }} AS mode_full_name,
        {{ generate_ntd_type_of_service_full_name('type_of_service') }} AS type_of_service_full_name,
        {{ generate_ntd_mode_service_type('stg.mode') }} AS service_type,

        stg.agency_mode_tos_date,
        stg.voms,
        stg.upt,
        stg._3_mode,
        stg.vrm,
        stg.uza_name,
        stg.uace_cd,
        stg.fta_region,
        stg.state,
        stg.reporter_type,
        stg.mode_type_of_service_status,
        stg.vrh,

        LAG(upt) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY month_first_day) AS upt_prior_year_month,
            upt - LAG(upt) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY month_first_day) AS upt_change_1yr,
        ROUND(SAFE_DIVIDE(
            (upt - LAG(upt) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY month_first_day)),
            LAG(upt) OVER (PARTITION BY ntd_id, mode, type_of_service ORDER BY month_first_day)
        ), 4) AS upt_pct_change_1yr,

        stg.legacy_ntd_id,
        stg.dt,
        stg.execution_ts
    FROM staging_complete_monthly_ridership_with_adjustments_and_estimates AS stg
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates
