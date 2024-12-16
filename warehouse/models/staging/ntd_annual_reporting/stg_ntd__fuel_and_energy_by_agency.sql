WITH external_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__fuel_and_energy_by_agency') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_fuel_and_energy_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__fuel_and_energy_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__fuel_and_energy_by_agency
