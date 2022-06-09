{{ config(materialized='table') }}

WITH shapes_clean AS (
    SELECT *
    FROM {{ ref('shapes_clean') }}
),

gtfs_schedule_dim_shapes AS (
    SELECT
        *,
        {{ farm_surrogate_key([
            'calitp_itp_id',
            'calitp_url_number',
            'calitp_extracted_at',
            'shape_id',
        ]) }} AS key
    FROM shapes_clean
)

SELECT * FROM gtfs_schedule_dim_shapes
