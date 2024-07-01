{{ config(materialized="table") }}
with
    dim_monthly_ntd_ridership_with_adjustments as (
        select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_joined") }}
    ),
ntd_modes as (
    select * from {{ ref("int_ntd__modes") }}
)
select
    uza_name,
    uace_cd,
    _dt,
    ts,
    ntd_id,
    year,
    reporter_type,
    agency,
    mode_type_of_service_status,
    mode,
    ntd_mode_full_name as mode_full_name,
    CASE
        WHEN mode IN ('AR', 'CC', 'CR', 'HR', 'YR', 'IP', 'LR', 'MG', 'SR', 'TR', 'MB', 'RB', 'CB', 'TB', 'FB', 'IP', 'MO', 'AG') THEN 'Fixed Route'
        WHEN mode IN ('DR', 'DT', 'VP', 'JT', 'PB') THEN 'Demand Response'
        ELSE 'Unknown' -- mode is null sometimes
    END AS service_type,
    _3_mode,
    tos,
    legacy_ntd_id,
    concat(period_year, '-',  lpad(period_month, 2, '0')) as period_year_month,
    period_year,
    period_month,
    upt,
    vrm,
    vrh,
    voms
from dim_monthly_ntd_ridership_with_adjustments
LEFT JOIN ntd_modes
ON
dim_monthly_ntd_ridership_with_adjustments.mode = ntd_modes.ntd_mode_abbreviation
