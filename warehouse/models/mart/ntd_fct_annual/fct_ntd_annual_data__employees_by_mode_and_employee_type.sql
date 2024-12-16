WITH staging_employees_by_mode_and_employee_type AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode_and_employee_type') }}
),

fct_ntd_annual_data__employees_by_mode_and_employee_type AS (
    SELECT *
    FROM staging_employees_by_mode_and_employee_type
)

SELECT * FROM fct_ntd_annual_data__employees_by_mode_and_employee_type
