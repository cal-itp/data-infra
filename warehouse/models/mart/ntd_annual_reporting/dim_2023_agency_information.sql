WITH staging_agency_information AS (
    SELECT *
    FROM {{ ref('stg_ntd__2023_agency_information') }}
),

dim_2023_agency_information AS (
    SELECT *
    FROM staging_agency_information
)

SELECT * FROM dim_2023_agency_information
