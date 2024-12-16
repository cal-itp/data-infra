WITH staging_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__fuel_and_energy_by_agency') }}
),

fct_fuel_and_energy_by_agency AS (
    SELECT *
    FROM staging_fuel_and_energy_by_agency
)

SELECT * FROM fct_fuel_and_energy_by_agency
