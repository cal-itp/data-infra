WITH staging_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_directly_generated') }}
),

fct_funding_sources_directly_generated AS (
    SELECT *
    FROM staging_funding_sources_directly_generated
)

SELECT * FROM fct_funding_sources_directly_generated
