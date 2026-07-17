WITH staging_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__summary_total') }}
),

fct_operating_and_capital_funding_time_series_summary_total AS (
    SELECT
        stg.year,
        stg.operating_national,
        stg.capital_national,
        stg.total_national,
        stg.operating_federal,
        stg.capital_federal,
        stg.total_federal,
        stg.operating_state,
        stg.capital_state,
        stg.total_state,
        stg.operating_local,
        stg.capital_local,
        stg.total_local,
        stg.operating_other,
        stg.capital_other,
        stg.total_other,
        stg.dt,
        stg.execution_ts

    FROM staging_operating_and_capital_funding_time_series_summary_total AS stg
)

SELECT * FROM fct_operating_and_capital_funding_time_series_summary_total
