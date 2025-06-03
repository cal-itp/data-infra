{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt"),
                exclude=[
                    "_3_mode",
                    "agency",
                    "legacy_ntd_id",
                    "mode",
                    "mode_type_of_service_status",
                    "ntd_id",
                    "reporter_type",
                    "tos",
                    "uace_cd",
                    "uza_name",
                    "dt",
                    "execution_ts"
                ],
                field_name="period",
                value_name="upt",
            )
        }}
    ),

    int_ntd__monthly_ridership_with_adjustments_upt AS (
        SELECT FORMAT("%05d", CAST(CAST(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
               legacy_ntd_id,
               agency,
               reporter_type,
               SAFE_CAST(SPLIT(period, '_')[OFFSET(2)] AS INT64) AS period_year,
               SPLIT(period, '_')[OFFSET(1)] AS period_month,
               uza_name,
               FORMAT("%05d", CAST(uace_cd AS INT64)) AS uace_cd,
               mode,
               mode_type_of_service_status,
               _3_mode,
               tos,
               upt,
               dt AS _dt,
               execution_ts
          FROM source_pivoted
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

SELECT * FROM int_ntd__monthly_ridership_with_adjustments_upt
