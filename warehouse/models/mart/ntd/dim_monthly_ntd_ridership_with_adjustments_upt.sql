WITH dim_monthly_ntd_ridership_with_adjustments_upt AS (
    SELECT *
    FROM {{ ref('int_ntd__monthly_ridership_with_adjustments_upt') }}
)
SELECT
    uza_name,
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
    period_month,
    period_year,
    value,
    FROM dim_monthly_ntd_ridership_with_adjustments_upt
