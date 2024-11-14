WITH staging_employees_by_agency AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__employees_by_agency') }}
),

fct_ntd_annual_data__employees_by_agency AS (
    SELECT *
    FROM staging_employees_by_agency
)

SELECT * FROM fct_ntd_annual_data__employees_by_agency
