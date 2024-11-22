WITH staging_maintenance_facilities_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__maintenance_facilities_by_agency') }}
),

fct_ntd_annual_data__maintenance_facilities_by_agency AS (
    SELECT *
    FROM staging_maintenance_facilities_by_agency
)

SELECT * FROM fct_ntd_annual_data__maintenance_facilities_by_agency
