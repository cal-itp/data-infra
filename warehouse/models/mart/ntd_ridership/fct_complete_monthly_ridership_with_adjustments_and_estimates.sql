{{ config(materialized="table") }}

WITH staging_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

ntd_modes as (
    SELECT * FROM {{ ref('ntd_modes_to_full_names') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['stg.ntd_id', 'stg.mode', 'stg.tos', 'period_month', 'period_year']) }} as key,

        stg.ntd_id,
        stg.agency,

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.date,
        stg.period_month,
        stg.period_year,
        stg.period_year_month,
        stg.tos,
        stg.mode,

        ntd_modes.ntd_mode_full_name AS mode_name,

        CASE
            WHEN stg.mode IN ('AG', 'AR', 'CB', 'CC', 'CR', 'FB', 'HR', 'IP', 'IP', 'LR', 'MB', 'MG', 'MO', 'RB', 'SR', 'TB', 'TR', 'YR')
            THEN 'Fixed Route'
            WHEN stg.mode IN ('DR', 'DT', 'VP', 'JT', 'PB')
            THEN 'Demand Response'
            ELSE 'Unknown' -- mode is null sometimes
        END AS service_type,

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
        stg.legacy_ntd_id,
        stg.dt,
        stg.execution_ts
    FROM staging_complete_monthly_ridership_with_adjustments_and_estimates AS stg
    LEFT JOIN current_dim_organizations AS orgs
        USING (ntd_id)
    LEFT JOIN ntd_modes
        ON stg.mode = ntd_modes.ntd_mode_abbreviation
    WHERE mode IN ("AG",
            "AR",
            "CB",
            "CC",
            "CR",
            "DR",
            "FB",
            "HR",
            "IP",
            "LR",
            "MB",
            "MG",
            "MO",
            "OR",
            "PB",
            "RB",
            "SR",
            "TB",
            "TR",
            "VP",
            "YR")
)

SELECT * FROM fct_complete_monthly_ridership_with_adjustments_and_estimates
