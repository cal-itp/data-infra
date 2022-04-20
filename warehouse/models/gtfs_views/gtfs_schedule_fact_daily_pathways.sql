{{ config(materialized='table') }}

WITH gtfs_schedule_dim_pathways AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_pathways') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
),

feed_pathways AS (
    SELECT
        T1.feed_key,
        T2.pathway_key,
        GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at) AS calitp_extracted_at,
        LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at) AS calitp_deleted_at
    FROM gtfs_schedule_dim_feeds AS T1
    INNER JOIN gtfs_schedule_dim_pathways AS T2
        USING (calitp_itp_id, calitp_url_number)
    WHERE
        T1.calitp_extracted_at < T2.calitp_deleted_at
        AND T2.calitp_extracted_at < T1.calitp_deleted_at
),

gtfs_schedule_fact_daily_pathways AS (
    SELECT
        T1.feed_key,
        T1.pathway_key,
        T2.full_date AS date,
        T1.* EXCEPT(feed_key, pathway_key)
    FROM feed_pathways AS T1
    INNER JOIN dim_date AS T2
        ON T1.calitp_extracted_at <= T2.full_date
            AND T1.calitp_deleted_at > T2.full_date
    WHERE T2.full_date <= CURRENT_DATE()
)

SELECT * FROM gtfs_schedule_fact_daily_pathways
