WITH
    source AS (
        SELECT *
          FROM {{ source('external_ntd__funding_and_expenses', 'historical__service_data_and_operating_expenses_time_series_by_mode__vrh') }}
    ),

    stg_ntd__service_data_and_operating_expenses_time_series_by_mode__vrh AS(
        SELECT *
          FROM source
        -- we pull the whole table every month in the pipeline, so this gets only the latest extract
        QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
    )

SELECT * FROM stg_ntd__service_data_and_operating_expenses_time_series_by_mode__vrh
