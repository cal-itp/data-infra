{{
    config(
        materialized='incremental',
        incremental_strategy='insert_overwrite',
        partition_by={
            'field': 'service_date',
            'data_type': 'date',
            'granularity': 'day',
        },
        cluster_by=['base64_url', 'schedule_base64_url'],
    )
}}

WITH fct_vehicle_locations AS (
    SELECT *
    FROM {{ ref('fct_vehicle_locations') }}
    WHERE {{ incremental_where(
        default_start_var='PROD_GTFS_RT_START',
        this_dt_column='dt',
        filter_dt_column='dt',
        dev_lookback_days=14)
    }}
),

-- collect points into an array
initial_pt_array AS (
    SELECT
        gtfs_dataset_key,
        gtfs_dataset_name,
        base64_url,
        service_date,
        schedule_gtfs_dataset_key,
        schedule_name,
        schedule_feed_key,
        schedule_base64_url,
        trip_id,
        trip_instance_key,
        -- don't try to make LINESTRING because of this issue:
        -- https://stackoverflow.com/questions/58234223/st-makeline-discarding-duplicate-points-even-if-not-consecutive
        -- also: https://gis.stackexchange.com/questions/426188/can-i-represent-a-route-that-doubles-back-on-itself-in-bigquery-with-a-linestrin
        -- so instead this is just an array of WKT points
        ARRAY_AGG(
            -- ignore nulls so it doesn't error out if there's a null point
            location IGNORE NULLS
            ORDER BY DATETIME(location_timestamp, "America/Los_Angeles")
        ) AS pt_array,
        -- count number of rows so we can check for nulls (drops) later
        ARRAY_AGG(
            DATETIME(location_timestamp, "America/Los_Angeles") IGNORE NULLS
            ORDER BY location_timestamp
        ) AS location_timestamp_pacific,
        ARRAY_AGG(
            EXTRACT(HOUR FROM DATETIME(location_timestamp, "America/Los_Angeles")) * 3600
              + EXTRACT(MINUTE FROM DATETIME(location_timestamp, "America/Los_Angeles")) * 60
              + EXTRACT(SECOND FROM DATETIME(location_timestamp, "America/Los_Angeles"))
             IGNORE NULLS
            ORDER BY location_timestamp
        ) AS pacific_seconds,
        COUNT(*) AS n_vp,

    FROM fct_vehicle_locations
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
),

fct_vehicle_locations_path AS (
    SELECT *
    FROM initial_pt_array
    -- drop shapes that had nulls
    WHERE ARRAY_LENGTH(pt_array) = n_vp
)

SELECT * FROM fct_vehicle_locations_path
