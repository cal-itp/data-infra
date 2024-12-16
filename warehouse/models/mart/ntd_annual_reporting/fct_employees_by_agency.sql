WITH staging_employees_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_agency') }}
),

fct_employees_by_agency AS (
    SELECT *
    FROM staging_employees_by_agency
)

SELECT * FROM fct_employees_by_agency
