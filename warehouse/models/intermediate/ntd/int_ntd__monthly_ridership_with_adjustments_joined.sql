{{ config(materialized="table") }}

with
    voms as (
        select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_voms") }}
    ),

    vrh as (select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_vrh") }}),
    vrm as (select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_vrm") }}),
    upt as (select * from {{ ref("int_ntd__monthly_ridership_with_adjustments_upt") }}),

    int_ntd__monthly_ridership_with_adjustments_joined as (
        select voms.*, upt.upt, vrm.vrm, vrh.vrh
        from voms

        full outer join
            upt
            on voms.ntd_id = upt.ntd_id
            and voms.year = upt.year
            and voms.mode = upt.mode
            and voms.reporter_type = upt.reporter_type
            and voms.agency = upt.agency
            and voms._3_mode = upt._3_mode
            and voms.period_month = upt.period_month
            and voms.period_year = upt.period_year
            and voms.tos = upt.tos
            and voms.uza_name = upt.uza_name

        full outer join
            vrm
            on voms.ntd_id = vrm.ntd_id
            and voms.year = vrm.year
            and voms.mode = vrm.mode
            and voms.reporter_type = vrm.reporter_type
            and voms.agency = vrm.agency
            and voms._3_mode = vrm._3_mode
            and voms.period_month = vrm.period_month
            and voms.period_year = vrm.period_year
            and voms.tos = vrm.tos
            and voms.uza_name = vrm.uza_name

        full outer join
            vrh
            on voms.ntd_id = vrh.ntd_id
            and voms.year = vrh.year
            and voms.mode = vrh.mode
            and voms.reporter_type = vrh.reporter_type
            and voms.agency = vrh.agency
            and voms._3_mode = vrh._3_mode
            and voms.period_month = vrh.period_month
            and voms.period_year = vrh.period_year
            and voms.tos = vrh.tos
            and voms.uza_name = vrh.uza_name
    )
select *
from int_ntd__monthly_ridership_with_adjustments_joined
