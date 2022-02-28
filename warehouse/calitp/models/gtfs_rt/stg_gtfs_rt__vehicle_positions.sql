
with source as (
    select * from {{ source('gtfs_rt_raw', 'vehicle_positions') }}
)

, stg_gtfs_rt__vehicle_positions as (
    select
          calitp_itp_id
        , calitp_url_number
        , calitp_filepath
        , id
        , header.timestamp as header_timestamp

    from source
)

select * from stg_gtfs_rt__vehicle_positions
