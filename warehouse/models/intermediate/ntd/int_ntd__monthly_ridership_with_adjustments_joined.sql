{{ config(materialized="table") }}

WITH
    voms AS (
        SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_voms") }}
    ),

    vrh AS (SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_vrh") }}),
    vrm AS (SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_vrm") }}),
    upt AS (SELECT * FROM {{ ref("int_ntd__monthly_ridership_with_adjustments_upt") }}),

    int_ntd__monthly_ridership_with_adjustments_joined AS (
        SELECT voms.*,
               upt.upt,
               vrm.vrm,
               vrh.vrh
          FROM voms

          FULL OUTER JOIN upt
            ON voms.ntd_id = upt.ntd_id
           AND voms.mode = upt.mode
           AND voms.reporter_type = upt.reporter_type
           AND voms.agency = upt.agency
           AND voms._3_mode = upt._3_mode
           AND voms.period_month = upt.period_month
           AND voms.period_year = upt.period_year
           AND voms.tos = upt.tos
           AND voms.mode_type_of_service_status = upt.mode_type_of_service_status

          FULL OUTER JOIN vrm
            ON voms.ntd_id = vrm.ntd_id
           AND voms.mode = vrm.mode
           AND voms.reporter_type = vrm.reporter_type
           AND voms.agency = vrm.agency
           AND voms._3_mode = vrm._3_mode
           AND voms.period_month = vrm.period_month
           AND voms.period_year = vrm.period_year
           AND voms.tos = vrm.tos
           AND voms.mode_type_of_service_status = vrm.mode_type_of_service_status

          FULL OUTER JOIN vrh
            ON voms.ntd_id = vrh.ntd_id
           AND voms.mode = vrh.mode
           AND voms.reporter_type = vrh.reporter_type
           AND voms.agency = vrh.agency
           AND voms._3_mode = vrh._3_mode
           AND voms.period_month = vrh.period_month
           AND voms.period_year = vrh.period_year
           AND voms.tos = vrh.tos
           AND voms.mode_type_of_service_status = vrh.mode_type_of_service_status
    -- where voms.ntd_id not in ("10089", "20170", "30069", "90178", "90179")
    -- These agencies have null for uace_cd and uza_name and perhaps are not good to
    -- have in the dataset.
    -- If you don't want them then add that where clause back in.
    )

SELECT * FROM int_ntd__monthly_ridership_with_adjustments_joined
