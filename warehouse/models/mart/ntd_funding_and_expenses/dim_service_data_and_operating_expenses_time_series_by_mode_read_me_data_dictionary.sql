WITH staging_service_data_and_operating_expenses_time_series_by_mode_read_me_data_dictionary AS (
    SELECT *
    FROM {{ ref('stg_ntd__service_data_and_operating_expenses_time_series_by_mode__read_me_data_dictionary') }}
),

dim_service_data_and_operating_expenses_time_series_by_mode_read_me_data_dictionary AS (
    SELECT *
    FROM staging_service_data_and_operating_expenses_time_series_by_mode_read_me_data_dictionary
)

SELECT *
FROM dim_service_data_and_operating_expenses_time_series_by_mode_read_me_data_dictionary
