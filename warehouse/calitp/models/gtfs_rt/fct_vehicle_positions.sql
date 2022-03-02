
with stg_gtfs_rt__vehicle_positions as (
    select * from {{ ref('stg_gtfs_rt__vehicle_positions') }}
)

select * from stg_gtfs_rt__vehicle_positions
