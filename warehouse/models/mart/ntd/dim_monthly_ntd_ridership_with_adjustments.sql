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
    _3_mode,
    tos,
    legacy_ntd_id,
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
