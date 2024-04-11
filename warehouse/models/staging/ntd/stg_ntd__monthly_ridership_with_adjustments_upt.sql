-- {{ config(materialized='table') }}

with source as (
  select * from {{ source('ntd_data_products', 'monthly_ridership_with_adjustments_upt') }}
),
stg_ntd__monthly_ridership_with_adjustments_upt AS(

    SELECT *
    FROM source
    -- we can have old months data in the source so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY ts DESC) = 1
)
Select * FROM stg_ntd__monthly_ridership_with_adjustments_upt
