{{ config(materialized='table') }}

WITH gtfs_schedule_dim_shapes_geo AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_shapes_geo') }}
)

, gtfs_schedule_dim_shapes_geo_latest as (
    select *
    from gtfs_schedule_dim_shapes_geo
    where calitp_deleted_at = '2099-01-01'
)

select * from gtfs_schedule_dim_shapes_geo_latest
