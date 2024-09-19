WITH external_2022_funding_sources_directly_generated AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2022__funding_sources_directly_generated') }}
),

stg_ntd_annual_data_tables__2022__funding_sources_directly_generated AS (
    SELECT *
    FROM external_2022_funding_sources_directly_generated
)

SELECT * FROM stg_ntd_annual_data_tables__2022__funding_sources_directly_generated
