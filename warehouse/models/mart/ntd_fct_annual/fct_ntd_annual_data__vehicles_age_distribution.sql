WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

fct_ntd_annual_data__vehicles_age_distribution AS (
    SELECT *
    FROM staging_vehicles_age_distribution
)

SELECT * FROM fct_ntd_annual_data__vehicles_age_distribution
