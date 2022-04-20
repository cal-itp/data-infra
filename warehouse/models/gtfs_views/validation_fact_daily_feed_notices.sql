{{ config(materialized='table') }}

WITH validation_notices_clean AS (
    SELECT *
    FROM {{ ref('validation_notices_clean') }}
),

dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

validation_fact_daily_feed_notices AS (
    SELECT
        T2.feed_key,
        D.full_date AS date,
        T1.calitp_extracted_at AS validation_created_at,
        T1.calitp_deleted_at AS validation_deleted_at,
        T1.* EXCEPT (calitp_extracted_at, calitp_deleted_at)

    FROM validation_notices_clean AS T1
    INNER JOIN dim_date AS D
        ON T1.calitp_extracted_at <= D.full_date
            AND T1.calitp_deleted_at > D.full_date
    INNER JOIN gtfs_schedule_dim_feeds AS T2
        ON T2.calitp_extracted_at <= D.full_date
            AND T2.calitp_deleted_at > D.full_date
            AND T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
    WHERE
        D.full_date < CURRENT_DATE()
)

SELECT * FROM validation_fact_daily_feed_notices
