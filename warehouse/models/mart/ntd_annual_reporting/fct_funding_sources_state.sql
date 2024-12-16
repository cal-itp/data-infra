WITH staging_funding_sources_state AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_state') }}
),

fct_funding_sources_state AS (
    SELECT *
    FROM staging_funding_sources_state
)

SELECT * FROM fct_funding_sources_state
