WITH staging_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ ref('staging', 'stg_ntd_annual_data__service_by_mode_and_time_period') }}
),

fct_ntd_annual_data__service_by_mode_and_time_period AS (
    SELECT *
    FROM staging_service_by_mode_and_time_period
)

SELECT * FROM fct_ntd_annual_data__service_by_mode_and_time_period
