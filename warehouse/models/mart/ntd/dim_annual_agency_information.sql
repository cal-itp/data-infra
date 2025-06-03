{{ config(materialized='view') }}

-- This table is deprecated, and temporarily pulling from the new production table fct_monthly_ridership_with_adjustments
WITH dim_annual_agency_information AS (
    SELECT * FROM {{ ref("dim_agency_information") }}
)

SELECT * FROM dim_annual_agency_information
