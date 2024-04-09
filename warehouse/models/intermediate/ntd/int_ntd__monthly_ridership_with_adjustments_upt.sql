WITH source AS (
    SELECT *
    FROM `cal-itp-data-infra-staging.vb_staging.stg_ntd__monthly_ridership_with_adjustments_upt`
),
int_ntd__monthly_ridership_with_adjustments_upt AS (
    SELECT uza_name,
        uace_cd,
        dt,
        ts,
        year,
        ntd_id,
        reporter_type,
        agency,
        STATUS,
        MODE,
        _3_mode,
        tos,
        legacy_ntd_id,
        SPLIT(period, '_') [OFFSET(1)] AS period_month,
        SPLIT(period, '_') [OFFSET(2)] AS period_year,
        value
    FROM source
)
SELECT *
FROM int_ntd__monthly_ridership_with_adjustments_upt
