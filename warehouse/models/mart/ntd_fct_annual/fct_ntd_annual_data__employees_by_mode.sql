WITH staging_employees_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__employees_by_mode') }}
),

fct_ntd_annual_data__employees_by_mode AS (
    SELECT *
    FROM staging_employees_by_mode
)

SELECT * FROM fct_ntd_annual_data__employees_by_mode
