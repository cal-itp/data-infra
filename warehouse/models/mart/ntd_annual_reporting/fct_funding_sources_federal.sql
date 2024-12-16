WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_federal') }}
),

fct_funding_sources_federal AS (
    SELECT *
    FROM staging_funding_sources_federal
)

SELECT * FROM fct_funding_sources_federal
