WITH staging_fuel_and_energy AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__fuel_and_energy') }}
),

fct_ntd_annual_data__fuel_and_energy AS (
    SELECT *
    FROM staging_fuel_and_energy
)

SELECT * FROM fct_ntd_annual_data__fuel_and_energy
