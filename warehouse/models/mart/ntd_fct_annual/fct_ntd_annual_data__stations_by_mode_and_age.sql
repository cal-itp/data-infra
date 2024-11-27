WITH staging_stations_by_mode_and_age AS (
    SELECT *
    FROM {{ ref('stg_ntd_annual_data__stations_by_mode_and_age') }}
),

fct_ntd_annual_data__stations_by_mode_and_age AS (
    SELECT *
    FROM staging_stations_by_mode_and_age
)

SELECT * FROM fct_ntd_annual_data__stations_by_mode_and_age
