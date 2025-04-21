WITH staging_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__summary_total') }}
),

fct_operating_and_capital_funding_time_series_summary_total AS (
    SELECT
        stg.unnamed__0,
        stg.unnamed__2,
        stg.unnamed__3,
        stg.unnamed__5,
        stg.unnamed__6,
        stg.unnamed__8,
        stg.unnamed__9,
        stg.unnamed__11,
        stg.unnamed__12,
        stg.unnamed__14,
        stg.unnamed__15,
        stg.federal,
        stg.state,
        stg.local,
        stg.other,
        stg.national_total,
        stg.dt,
        stg.execution_ts
    FROM staging_operating_and_capital_funding_time_series_summary_total AS stg
    WHERE stg.state = 'CA'
)

SELECT * FROM fct_operating_and_capital_funding_time_series_summary_total
