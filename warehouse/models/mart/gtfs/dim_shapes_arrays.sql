{{
    config(
        materialized='table',
        cluster_by='feed_key',
    )
}}


WITH dim_shapes AS (
    SELECT * FROM {{ ref('dim_shapes') }}
),

-- first, cast lat/long to geography
lat_long AS (
    SELECT
        feed_key,
        base64_url,
        shape_id,
        shape_pt_sequence,
        ST_GEOGPOINT(
            shape_pt_lon,
            shape_pt_lat
        ) AS pt_geom,
        _feed_valid_from,
    FROM dim_shapes
),

-- collect points into an array
initial_pt_array AS (
    SELECT
        feed_key,
        base64_url,
        shape_id,
        _feed_valid_from,
        -- don't try to make LINESTRING because of this issue:
        -- https://stackoverflow.com/questions/58234223/st-makeline-discarding-duplicate-points-even-if-not-consecutive
        -- also: https://gis.stackexchange.com/questions/426188/can-i-represent-a-route-that-doubles-back-on-itself-in-bigquery-with-a-linestrin
        -- so instead this is just an array of WKT points
        ARRAY_AGG(
            -- ignore nulls so it doesn't error out if there's a null point
            pt_geom IGNORE NULLS
            ORDER BY shape_pt_sequence)
        AS pt_array,
        -- count number of rows so we can check for nulls (drops) later
        COUNT(*) AS ct
    FROM lat_long
    GROUP BY feed_key, base64_url, shape_id, _feed_valid_from
),

dim_shapes_arrays AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'shape_id']) }} AS key,
        feed_key,
        shape_id,
        pt_array,
        base64_url,
        _feed_valid_from,
    FROM initial_pt_array
    -- drop shapes that had nulls
    WHERE ARRAY_LENGTH(pt_array) = ct
)

SELECT * FROM dim_shapes_arrays
