WITH external_2022_breakdowns AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__breakdowns') }}
),

stg_ntd_annual_data_tables__2022__breakdowns AS (
    SELECT *
    FROM external_2022_breakdowns
)

SELECT * FROM stg_ntd_annual_data_tables__2022__breakdowns
