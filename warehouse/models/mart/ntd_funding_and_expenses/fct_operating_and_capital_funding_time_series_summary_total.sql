WITH staging_operating_and_capital_funding_time_series_summary_total AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__summary_total') }}
),

fct_operating_and_capital_funding_time_series_summary_total AS (
    SELECT
        local_operating,
        state_operating,
        federal_operating,
        other_operating,
        national_operating,
        year,
        national_capital,
        national_total,
        federal_capital,
        federal_total,
        state_capital,
        state_total,
        local_capital,
        local_total,
        stg.other_capital,
        stg.other_total,



    FROM staging_operating_and_capital_funding_time_series_summary_total AS stg
)

SELECT * FROM fct_operating_and_capital_funding_time_series_summary_total
