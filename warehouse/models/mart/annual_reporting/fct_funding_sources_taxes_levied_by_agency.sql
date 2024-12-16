WITH staging_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__funding_sources_taxes_levied_by_agency') }}
),

fct_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM staging_funding_sources_taxes_levied_by_agency
)

SELECT * FROM fct_funding_sources_taxes_levied_by_agency
