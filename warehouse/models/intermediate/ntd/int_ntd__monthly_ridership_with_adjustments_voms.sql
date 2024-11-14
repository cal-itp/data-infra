{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd_ridership_historical__complete_monthly_ridership_with_adjustments_and_estimates__voms"),
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
                value_name="voms",
            )
        }}
    ),

    int_ntd__monthly_ridership_with_adjustments_voms AS (
        SELECT format("%05d", cast(cast(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
               legacy_ntd_id,
               agency,
               reporter_type,
               split(period, '_')[offset(2)] AS period_year,
               split(period, '_')[offset(1)] AS period_month,
               uza_name,
               format("%05d", cast(uace_cd AS INT64)) AS uace_cd,
               mode,
               mode_type_of_service_status,
               _3_mode,
               tos,
               voms,
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

SELECT * FROM int_ntd__monthly_ridership_with_adjustments_voms
