WITH staging_maintenance_facilities AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities') }}
),

fct_maintenance_facilities AS (
    SELECT *
    FROM staging_maintenance_facilities
)

SELECT * FROM fct_maintenance_facilities
