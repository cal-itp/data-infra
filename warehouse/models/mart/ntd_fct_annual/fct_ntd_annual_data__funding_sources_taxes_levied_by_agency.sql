WITH staging_funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__funding_sources_taxes_levied_by_agency') }}
),

fct_ntd_annual_data__funding_sources_taxes_levied_by_agency AS (
    SELECT *
    FROM staging_funding_sources_taxes_levied_by_agency
)

SELECT * FROM fct_ntd_annual_data__funding_sources_taxes_levied_by_agency
