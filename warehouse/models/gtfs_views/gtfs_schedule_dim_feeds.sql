{{ config(materialized='table') }}

WITH calitp_feeds AS (
    SELECT *
    FROM {{ ref('calitp_feeds') }}
),

-- this is a slightly hacky workaround to address feed_info.txt files that contain two rows
-- specifically, this was an issue for Foothill Transit from May 2022 onward
-- we are just semi-arbitrarily picking the row that has longer feed dates specified
feed_info_clean AS (
    SELECT
        *,
        RANK() OVER (
            PARTITION BY
                calitp_itp_id,
                calitp_url_number,
                feed_start_date,
                feed_version,
                calitp_extracted_at
            ORDER BY feed_end_date DESC
        ) AS rank
    FROM {{ ref('feed_info_clean') }}
),

feed_feed_info AS (
    SELECT
        T1.calitp_itp_id,
        T1.calitp_url_number,
        * EXCEPT(calitp_itp_id, calitp_url_number, calitp_extracted_at, calitp_deleted_at, calitp_hash),
        -- TODO: MTC 511 is a composite feed, and has multiple feed_info entries,
        -- that join to feed_info -> agency -> routes. However this violates a common
        -- business question, "how many feeds have feed_info.x?", and seems to go
        -- against the data schema. Mark here and remove feed_info for it via where clause
        IF(T1.calitp_itp_id = 200, TRUE, FALSE)
        AS is_composite_feed,
        COALESCE(GREATEST(T1.calitp_extracted_at, T2.calitp_extracted_at), T1.calitp_extracted_at) AS calitp_extracted_at,
        COALESCE(LEAST(T1.calitp_deleted_at, T2.calitp_deleted_at), T1.calitp_deleted_at) AS calitp_deleted_at
    FROM calitp_feeds AS T1
    LEFT JOIN feed_info_clean AS T2
        ON
            T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.calitp_extracted_at < T2.calitp_deleted_at
            AND T2.calitp_extracted_at < T1.calitp_deleted_at
            AND T2.calitp_itp_id != 200
            AND T2.rank = 1
),

gtfs_schedule_dim_feeds AS (
    SELECT
        FARM_FINGERPRINT(CONCAT(
            T.feed_key, "___",
            COALESCE(CAST(T.feed_info_key AS STRING), "NULL")
        )) AS feed_key,
        * EXCEPT(feed_key, feed_info_key)
    FROM feed_feed_info AS T
)

SELECT * FROM gtfs_schedule_dim_feeds
