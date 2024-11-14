WITH staging_metrics AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__metrics') }}
),

fct_ntd_annual_data__metrics AS (
    SELECT *
    FROM staging_metrics
)

SELECT * FROM fct_ntd_annual_data__metrics
