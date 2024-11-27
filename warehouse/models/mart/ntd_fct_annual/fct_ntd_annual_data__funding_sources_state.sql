WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__funding_sources_state') }}
),

fct_ntd_annual_data__funding_sources_state AS (
    SELECT *
    FROM staging_funding_sources_state
)

SELECT * FROM fct_ntd_annual_data__funding_sources_state
