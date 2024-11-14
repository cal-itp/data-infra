WITH staging_funding_sources_federal AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__funding_sources_federal') }}
),

fct_ntd_annual_data__funding_sources_federal AS (
    SELECT *
    FROM staging_funding_sources_federal
)

SELECT * FROM fct_ntd_annual_data__funding_sources_federal
