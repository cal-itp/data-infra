WITH staging_service_by_mode AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__service_by_mode') }}
),

fct_ntd_annual_data__service_by_mode AS (
    SELECT *
    FROM staging_service_by_mode
)

SELECT * FROM fct_ntd_annual_data__service_by_mode
