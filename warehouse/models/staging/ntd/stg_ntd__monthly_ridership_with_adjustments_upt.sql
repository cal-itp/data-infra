-- {{ config(materialized='table') }}
with
    source as (
        select *
        from {{ source("ntd_data_products", "monthly_ridership_with_adjustments_upt") }}
    ),
    stg_ntd__monthly_ridership_with_adjustments_upt as (

        select *
        from source
        -- we can have old months data in the source so this gets only the latest
        -- extract
        qualify dense_rank() over (order by ts desc) = 1
    )
select *
from stg_ntd__monthly_ridership_with_adjustments_upt
