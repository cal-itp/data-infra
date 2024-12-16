WITH staging_agency_information AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_agency_information') }}
),

fct_ntd_annual_data__2023_agency_information AS (
    SELECT *
    FROM staging_agency_information
)

SELECT * FROM fct_ntd_annual_data__2023_agency_information
