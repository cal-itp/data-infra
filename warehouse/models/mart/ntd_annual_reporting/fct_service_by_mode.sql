WITH staging_service_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_mode') }}
),

fct_service_by_mode AS (
    SELECT *
    FROM staging_service_by_mode
)

SELECT * FROM fct_service_by_mode
