WITH staging_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__fuel_and_energy_by_agency') }}
),

fct_ntd_annual_data__fuel_and_energy_by_agency AS (
    SELECT *
    FROM staging_fuel_and_energy_by_agency
)

SELECT * FROM fct_ntd_annual_data__fuel_and_energy_by_agency
