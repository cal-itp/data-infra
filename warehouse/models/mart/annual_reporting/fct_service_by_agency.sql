WITH staging_service_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_agency') }}
),

fct_service_by_agency AS (
    SELECT *
    FROM staging_service_by_agency
)

SELECT * FROM fct_service_by_agency
