WITH staging_operating_and_capital_funding_time_series_read_me_data_dictionary AS (
    SELECT *
    FROM {{ ref('stg_ntd__operating_and_capital_funding_time_series__read_me_data_dictionary') }}
),

dim_operating_and_capital_funding_time_series_read_me_data_dictionary AS (
    SELECT *
    FROM staging_operating_and_capital_funding_time_series_read_me_data_dictionary
)

SELECT *
FROM dim_operating_and_capital_funding_time_series_read_me_data_dictionary
