WITH staging_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__summary_total') }}
),

fct_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM staging_operating_and_capital_funding_time_series_summary_total
)

SELECT
    unnamed__0,
    unnamed__2,
    unnamed__3,
    unnamed__5,
    unnamed__6,
    unnamed__8,
    unnamed__9,
    unnamed__11,
    unnamed__12,
    unnamed__14,
    unnamed__15,
    federal,
    state,
    local,
    other,
    national_total,
    dt,
    execution_ts
FROM fct_operating_and_capital_funding_time_series_summary_total
