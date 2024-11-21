{{ config(materialized="table") }}

WITH
    source AS (
        SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_joined") }}
    ),

    ntd_modes AS (
        SELECT * FROM {{ ref("int_ntd__modes") }}
    ),

    dim_monthly_ridership_with_adjustments AS (
        SELECT {{ dbt_utils.generate_surrogate_key(['ntd_id', 'mode', 'tos', 'period_month', 'period_year']) }} as key,
               ntd_id,
               legacy_ntd_id,
               agency,
               reporter_type,
               concat(period_year, '-',  lpad(period_month, 2, '0')) AS period_year_month,
               period_year,
               period_month,
               uza_name AS primary_uza_name,
               uace_cd AS primary_uza_code,
               _3_mode,
               mode,
               ntd_mode_full_name AS mode_name,
               CASE
                   WHEN mode IN ('AG', 'AR', 'CB', 'CC', 'CR', 'FB', 'HR', 'IP', 'IP', 'LR', 'MB', 'MG', 'MO', 'RB', 'SR', 'TB', 'TR', 'YR')
                   THEN 'Fixed Route'
                   WHEN mode IN ('DR', 'DT', 'VP', 'JT', 'PB')
                   THEN 'Demand Response'
                   ELSE 'Unknown' -- mode is null sometimes
               END AS service_type,
               mode_type_of_service_status,
               tos,
               upt,
               vrm,
               vrh,
               voms,
               _dt,
               execution_ts
          FROM source
          LEFT JOIN ntd_modes
            ON source.mode = ntd_modes.ntd_mode_abbreviation
    )

SELECT * FROM dim_monthly_ridership_with_adjustments
