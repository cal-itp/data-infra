WITH staging_vehicles_age_distribution AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_age_distribution') }}
),

fct_vehicles_age_distribution AS (
    SELECT *
    FROM staging_vehicles_age_distribution
)

SELECT * FROM fct_vehicles_age_distribution
