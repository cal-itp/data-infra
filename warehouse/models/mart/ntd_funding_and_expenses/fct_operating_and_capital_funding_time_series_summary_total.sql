WITH staging_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__summary_total') }}
),

fct_operating_and_capital_funding_time_series_summary_total AS (
    SELECT
        stg.year,
        stg.national_operating,
        stg.national_capital,
        stg.national_total,
        stg.federal_operating,
        stg.federal_capital,
        stg.federal_total,
        stg.state_operating,
        stg.state_capital,
        stg.state_total,
        stg.local_operating,
        stg.local_capital,
        stg.local_total,
        stg.other_operating,
        stg.other_capital,
        stg.other_total

    FROM staging_operating_and_capital_funding_time_series_summary_total AS stg
)

SELECT * FROM fct_operating_and_capital_funding_time_series_summary_total
