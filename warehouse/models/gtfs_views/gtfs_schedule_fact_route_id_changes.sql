{{ config(materialized='table') }}

WITH dim_metric_date AS (
    SELECT *
    FROM {{ ref('dim_metric_date') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

gtfs_schedule_dim_routes AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_routes') }}
),

date_range AS (
    SELECT
        metric_period,
        metric_date,
        start_date,
        end_date
    FROM dim_metric_date
    WHERE
        is_gtfs_schedule_range
        AND metric_type != "daily"
),

source_table AS (

    SELECT
        *,
        route_id AS source_id
    FROM gtfs_schedule_dim_routes

),

table_start AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        metric_period,
        metric_date,
        source_id
    FROM source_table
    INNER JOIN date_range ON calitp_extracted_at <= start_date
        AND calitp_deleted_at > start_date
),

table_end AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        metric_period,
        metric_date,
        source_id
    FROM source_table
    INNER JOIN date_range ON calitp_extracted_at <= end_date
        AND calitp_deleted_at > end_date
),

table_partial AS (
    SELECT
        * EXCEPT (source_id),
        t1.source_id AS start_table_source_id,
        t2.source_id AS stop_table_source_id,
        CASE
            WHEN t2.source_id IS NULL AND t1.source_id IS NOT NULL THEN 'Removed'
            WHEN t1.source_id IS NULL AND t2.source_id IS NOT NULL THEN 'Added'
            ELSE 'Unchanged'
        END AS change_status
    FROM table_start AS t1
    FULL JOIN table_end AS t2
              USING ( calitp_itp_id, calitp_url_number, metric_period, metric_date, source_id)

),

metric_counts AS (

    SELECT
        calitp_itp_id,
        calitp_url_number,
        metric_period,
        metric_date,
        change_status,
        COUNT(*) AS n
    FROM table_partial GROUP BY 1, 2, 3, 4, 5

),

gtfs_schedule_fact_route_id_changes AS (
    SELECT
        T2.feed_key,
        T1.*
    FROM metric_counts AS T1
    INNER JOIN gtfs_schedule_dim_feeds AS T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T2.calitp_extracted_at <= T1.metric_date
        AND T2.calitp_deleted_at > T1.metric_date
)

SELECT * FROM gtfs_schedule_fact_route_id_changes
