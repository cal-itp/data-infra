WITH staging_monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM {{ ref('stg_ntd__monthly_modal_time_series_safety_and_service') }}
),

fct_safety_and_security__monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM staging_monthly_modal_time_series_safety_and_service
)

SELECT * FROM fct_safety_and_security__monthly_modal_time_series_safety_and_service
