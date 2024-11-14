WITH staging_service_by_agency AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__service_by_agency') }}
),

fct_ntd_annual_data__service_by_agency AS (
    SELECT *
    FROM staging_service_by_agency
)

SELECT * FROM fct_ntd_annual_data__service_by_agency
