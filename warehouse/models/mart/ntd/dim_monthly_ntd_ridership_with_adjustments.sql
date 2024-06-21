{{ config(materialized="table") }}
with
    dim_monthly_ntd_ridership_with_adjustments as (
        select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_joined") }}
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
