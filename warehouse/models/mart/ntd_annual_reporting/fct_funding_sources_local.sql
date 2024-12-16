WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_local') }}
),

fct_funding_sources_local AS (
    SELECT *
    FROM staging_funding_sources_local
)

SELECT * FROM fct_funding_sources_local
