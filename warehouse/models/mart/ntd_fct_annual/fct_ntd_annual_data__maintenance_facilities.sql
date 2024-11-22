WITH staging_maintenance_facilities AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__maintenance_facilities') }}
),

fct_ntd_annual_data__maintenance_facilities AS (
    SELECT *
    FROM staging_maintenance_facilities
)

SELECT * FROM fct_ntd_annual_data__maintenance_facilities
