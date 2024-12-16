WITH staging_service_by_mode_and_time_period AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_by_mode_and_time_period') }}
),

fct_service_by_mode_and_time_period AS (
    SELECT *
    FROM staging_service_by_mode_and_time_period
)

SELECT * FROM fct_service_by_mode_and_time_period
