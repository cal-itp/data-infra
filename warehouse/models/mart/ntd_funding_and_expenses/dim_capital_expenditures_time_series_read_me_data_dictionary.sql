WITH staging_capital_expenditures_time_series_read_me_data_dictionary AS (
    SELECT *
    FROM {{ ref('stg_ntd__capital_expenditures_time_series__read_me_data_dictionary') }}
),

dim_capital_expenditures_time_series_read_me_data_dictionary AS (
    SELECT *
    FROM staging_capital_expenditures_time_series_read_me_data_dictionary
)

SELECT *
FROM dim_capital_expenditures_time_series_read_me_data_dictionary
