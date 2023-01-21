{{ config(materialized='ephemeral') }}

WITH int_gtfs_rt__daily_url_index  AS (
    SELECT * FROM {{ ref('int_gtfs_rt__daily_url_index') }}
),

-- we never want results from the current date, as data will be incomplete
int_gtfs_quality__rt_url_guideline_index AS (
    SELECT
        dt AS date,
        base64_url,
        type AS feed_type
    FROM int_gtfs_rt__daily_url_index
    WHERE dt < CURRENT_DATE
)

SELECT * FROM int_gtfs_quality__rt_url_guideline_index
