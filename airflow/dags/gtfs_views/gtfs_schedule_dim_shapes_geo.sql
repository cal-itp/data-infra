---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_schedule_dim_shapes_geo"

description: |
 Constructs the shape geometry for each shape from gtfs_schedule_dim_shapes.

fields:
  calitp_itp_id: ITP ID
  calitp_url_number: URL number
  calitp_extracted_at: Date extracted
  calitp_deleted_at: Date deleted; 2099-01-01 indicates not yet deleted (still active)
  shape_id: Shape ID from original GTFS feed
  pt_array: An array of WKT points, in order, that make up this shape.

dependencies:
  - gtfs_schedule_dim_shapes

tests:
  check_null:
    - calitp_itp_id
    - calitp_url_number
    - calitp_extracted_at
    - calitp_deleted_at
    - shape_id
    - pt_array
  check_composite_unique:
    - calitp_itp_id
    - calitp_url_number
    - shape_id
    - calitp_extracted_at
---

-- note that we can't just use shape_key
-- because that's assigned at the row (i.e., point) level
-- so we have to use itp id + url num + extracted + deleted + shape ID as unique ID
-- TODO: make a better identifier here

-- first, cast lat/long to geography
WITH lat_long as (
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
            ) as pt_geom
        FROM `views.gtfs_schedule_dim_shapes`
    ),
  -- get all the times that any point in the shape was extracted
  unique_extracts AS (
    SELECT DISTINCT
      calitp_itp_id,
      calitp_url_number,
      shape_id,
      calitp_extracted_at as event_date
    FROM lat_long
  ),
   -- get all the times that any point in the shape was deleted
  unique_deletions AS (
    SELECT DISTINCT
      calitp_itp_id,
      calitp_url_number,
      shape_id,
      calitp_deleted_at as event_date
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
      event_date as calitp_extracted_at,
      LEAD(event_date)
        OVER(
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                shape_id
            ORDER BY
                event_date
        ) as calitp_deleted_at
    FROM all_events
  ),
  -- remove the rows noted above
  -- where extracted date = deleted date or deleted is null
  versioned_shapes AS (
    SELECT *
    FROM first_versioning
    WHERE calitp_extracted_at <> calitp_deleted_at
        AND calitp_deleted_at IS NOT NULL
  ),
  -- now that we have shape-level extraction/deletion log
  -- re-join with the individual points
  versioned_lat_long AS (
    SELECT l.* EXCEPT(calitp_extracted_at, calitp_deleted_at),
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
          as pt_array,
        -- count number of rows so we can check for nulls (drops) later
        count(1) as ct
    FROM versioned_lat_long
    GROUP BY
        calitp_itp_id,
        calitp_url_number,
        calitp_extracted_at,
        calitp_deleted_at,
        shape_id
  )

  SELECT * EXCEPT(ct)
  FROM initial_pt_array
  -- drop shapes that had nulls
  WHERE ARRAY_LENGTH(pt_array) = ct
