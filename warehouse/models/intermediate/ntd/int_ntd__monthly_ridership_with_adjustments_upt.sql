with
    source_pivoted as (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__monthly_ridership_with_adjustments_upt"),
                exclude=[
                    "uza_name",
                    "uace_cd",
                    "dt",
                    "ts",
                    "year",
                    "ntd_id",
                    "reporter_type",
                    "agency",
                    "mode_type_of_service_status",
                    "mode",
                    "_3_mode",
                    "tos",
                    "legacy_ntd_id",
                ],
                field_name="period",
                value_name="upt",
            )
        }}
    ),
    int_ntd__monthly_ridership_with_adjustments_upt as (
        select
            uza_name,
            format("%05d", cast(uace_cd as int64)) as uace_cd,
            dt as _dt,
            ts,
            year,
            format("%05d", cast(ntd_id as int64)) as ntd_id,
            legacy_ntd_id,
            reporter_type,
            agency,
            mode_type_of_service_status,
            mode,
            _3_mode,
            tos,
            split(period, '_')[offset(2)] as period_year,
            split(period, '_')[offset(1)] as period_month,
            upt
        from source_pivoted
        where
            mode in (
                "DR",
                "FB",
                "LR",
                "MB",
                "SR",
                "TB",
                "VP",
                "CB",
                "RB",
                "CR",
                "YR",
                "MG",
                "MO",
                "AR",
                "TR",
                "HR",
                "OR",
                "IP",
                "AG",
                "PB",
                "CC"
            )
    )
select *
from int_ntd__monthly_ridership_with_adjustments_upt
