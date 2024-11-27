WITH staging_funding_sources_local AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__funding_sources_local') }}
),

fct_ntd_annual_data__funding_sources_local AS (
    SELECT *
    FROM staging_funding_sources_local
)

SELECT * FROM fct_ntd_annual_data__funding_sources_local
