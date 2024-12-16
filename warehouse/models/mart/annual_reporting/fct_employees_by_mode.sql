WITH staging_employees_by_mode AS (
    SELECT *
    FROM {{ ref('stg_ntd__employees_by_mode') }}
),

fct_employees_by_mode AS (
    SELECT *
    FROM staging_employees_by_mode
)

SELECT * FROM fct_employees_by_mode
