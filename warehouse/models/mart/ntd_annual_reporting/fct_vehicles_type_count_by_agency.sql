WITH staging_vehicles_type_count_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__vehicles_type_count_by_agency') }}
),

fct_vehicles_type_count_by_agency AS (
    SELECT *
    FROM staging_vehicles_type_count_by_agency
)

SELECT * FROM fct_vehicles_type_count_by_agency
