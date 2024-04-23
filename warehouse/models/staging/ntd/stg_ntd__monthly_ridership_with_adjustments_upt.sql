-- {{ config(materialized='table') }}

with source as (
  select * from {{ source('ntd_data_products', 'monthly_ridership_with_adjustments_upt') }}
),
stg_ntd__monthly_ridership_with_adjustments_upt AS(

    SELECT *
    FROM source
    -- we can have old months data in the source so this gets only the latest extract
    Qualify DENSE_RANK() OVER (ORDER BY ts DESC) = 1
)
Select * FROM stg_ntd__monthly_ridership_with_adjustments_upt
where mode in ("DR","FB","LR","MB","SR","TB","VP","CB","RB","CR","YR","MG","MO","AR","TR","HR","OR","IP","AG")
