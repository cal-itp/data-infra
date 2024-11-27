WITH staging_vehicles_type_count_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__vehicles_type_count_by_agency') }}
),

fct_ntd_annual_data__vehicles_type_count_by_agency AS (
    SELECT *
    FROM staging_vehicles_type_count_by_agency
)

SELECT * FROM fct_ntd_annual_data__vehicles_type_count_by_agency
