WITH external_monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__monthly_modal_time_series_safety_and_service') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_monthly_modal_time_series_safety_and_service
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_safety_and_security__monthly_modal_time_series_safety_and_service AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_safety_and_security__monthly_modal_time_series_safety_and_service
