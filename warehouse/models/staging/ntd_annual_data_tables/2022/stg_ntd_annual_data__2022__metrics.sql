WITH external_2022_metrics AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__metrics') }}
),

stg_ntd_annual_data_tables__2022__metrics AS (
    SELECT *
    FROM external_2022_metrics
)

SELECT * FROM stg_ntd_annual_data_tables__2022__metrics
