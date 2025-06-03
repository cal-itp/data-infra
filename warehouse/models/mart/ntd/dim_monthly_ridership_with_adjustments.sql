{{ config(materialized='view') }}

-- This table is deprecated, and temporarily pulling from the new production table fct_monthly_ridership_with_adjustments
WITH dim_monthly_ridership_with_adjustments AS (
    SELECT * FROM {{ ref("fct_monthly_ridership_with_adjustments") }}
)

SELECT * FROM dim_monthly_ridership_with_adjustments
