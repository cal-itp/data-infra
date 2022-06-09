{{ config(materialized='table') }}

WITH gtfs_schedule_dim_shapes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_shapes') }}
),
-- note that we can't just use shape_key
-- because that's assigned at the row (i.e., point) level
-- so we have to use itp id + url num + extracted + deleted + shape ID as unique ID
-- TODO: make a better identifier here

-- first, cast lat/long to geography
lat_long AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        calitp_extracted_at,
        calitp_deleted_at,
        shape_id,
        shape_pt_sequence,
        ST_GEOGPOINT(
            shape_pt_lon,
            shape_pt_lat
        ) AS pt_geom
    FROM gtfs_schedule_dim_shapes
),

-- get all the times that any point in the shape was extracted
unique_extracts AS (
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        shape_id,
        calitp_extracted_at AS event_date
    FROM lat_long
),

-- get all the times that any point in the shape was deleted
unique_deletions AS (
    SELECT DISTINCT
        calitp_itp_id,
        calitp_url_number,
        shape_id,
        calitp_deleted_at AS event_date
    FROM lat_long
),

-- at the shape level, any time that a point changes (addition or deletion)
-- we need to treat that as the shape being re-extracted
-- so, combine all point extractions + deletions into one table
all_events AS (
    SELECT *
    FROM unique_extracts
    UNION ALL
    SELECT *
    FROM unique_deletions
),

-- create a shape-level log of extractions + deletions
-- this will have rows where extracted date = deleted date
-- and the final row has deleted = null
first_versioning AS (
    SELECT
        * EXCEPT(event_date),
        event_date AS calitp_extracted_at,
        LEAD(event_date)
        OVER(
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                shape_id
            ORDER BY
                event_date
        ) AS calitp_deleted_at
    FROM all_events
),

-- remove the rows noted above
-- where extracted date = deleted date or deleted is null
versioned_shapes AS (
    SELECT *
    FROM first_versioning
    WHERE calitp_extracted_at != calitp_deleted_at
        AND calitp_deleted_at IS NOT NULL
),

-- now that we have shape-level extraction/deletion log
-- re-join with the individual points
versioned_lat_long AS (
    SELECT
        l.* EXCEPT(calitp_extracted_at, calitp_deleted_at),
        s.calitp_extracted_at,
        s.calitp_deleted_at
    FROM versioned_shapes AS s
    LEFT JOIN lat_long AS l
        ON s.calitp_itp_id = l.calitp_itp_id
            AND s.calitp_url_number = l.calitp_url_number
            AND s.shape_id = l.shape_id
            -- do not use strict equality here
            -- because with point-level versioning
            -- points can persist across shape-level extraction/deletion
            AND s.calitp_extracted_at >= l.calitp_extracted_at
            AND s.calitp_deleted_at <= l.calitp_deleted_at
),

-- collect points into an array
initial_pt_array AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        shape_id,
        calitp_extracted_at,
        calitp_deleted_at,
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
    FROM versioned_lat_long
    GROUP BY
        calitp_itp_id,
        calitp_url_number,
        calitp_extracted_at,
        calitp_deleted_at,
        shape_id
),

gtfs_schedule_dim_shapes_geo AS (
    SELECT
        * EXCEPT(ct),
        {{ farm_surrogate_key([
            'calitp_itp_id',
            'calitp_url_number',
            'calitp_extracted_at',
            'shape_id',
        ]) }} AS key
    FROM initial_pt_array
    -- drop shapes that had nulls
    WHERE ARRAY_LENGTH(pt_array) = ct
)

SELECT * FROM gtfs_schedule_dim_shapes_geo
