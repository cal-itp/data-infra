{{ config(materialized='table') }}

WITH calitp_status AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_status') }}
),

raw_feed_urls AS (
    SELECT
        *,
        PARSE_DATE(
            '%Y-%m-%d',
            REGEXP_EXTRACT(_FILE_NAME, ".*/([0-9]+-[0-9]+-[0-9]+)")
        ) AS calitp_extracted_at
    FROM {{ source('gtfs_schedule_history', 'calitp_feeds_raw') }}
),

semi_safe_urls AS (
    -- there are uncensored URLs with API keys
    -- in the early days of calitp_feeds_raw and before its implementation
    SELECT
        T1.itp_id,
        T1.url_number,
        T1.calitp_extracted_at,
        COALESCE(T2.gtfs_schedule_url, T1.gtfs_schedule_url) AS almost_safe_url
    FROM calitp_status AS T1
    LEFT JOIN raw_feed_urls AS T2 USING (itp_id, url_number, calitp_extracted_at)
    ORDER BY calitp_extracted_at
),


safe_urls AS (
    SELECT
        itp_id,
        url_number,
        calitp_extracted_at,
        (CASE
            WHEN (almost_safe_url LIKE r"%api.actransit.org/transit/gtfs/download?token=%")
                AND (almost_safe_url NOT LIKE r"%api.actransit.org/transit/gtfs/download?token={\%")
                THEN REGEXP_REPLACE(
                    almost_safe_url,
                    "token=[a-zA-Z0-9-]+", {% raw %}"token={{ AC_TRANSIT_API_KEY }}"{% endraw %}
                )
            WHEN (almost_safe_url LIKE r"%api.511.org/transit/%?api_key=%")
                AND (almost_safe_url NOT LIKE r"%api.511.org/transit/%?api_key={\%")
                THEN REGEXP_REPLACE(
                    almost_safe_url,
                    "api_key=[a-zA-Z0-9-]+", {% raw %}"api_key={{ MTC_511_API_KEY }}"{% endraw %}
                )
            ELSE almost_safe_url
            END) AS gtfs_schedule_url
    FROM semi_safe_urls
),

-- TODO: can we use raw URL (no API keys) here in the hash too?
gtfs_schedule_feed_snapshot AS (
    SELECT
        itp_id,
        url_number,
        gtfs_schedule_url,
        agency_name,
        status,
        calitp_extracted_at,
        -- Do a concat rather than just md5 on gtfs_schedule_feed as we only want to
        -- hash on those 5 columns (i.e dont want to hash on extracted at)
        TO_BASE64(MD5(
                CONCAT(
                    CAST(itp_id AS STRING), "__", CAST(url_number AS STRING), "__",
                    COALESCE(CAST(gtfs_schedule_url AS STRING), "_NULL_"), "__",
                    COALESCE(CAST(agency_name AS STRING), "_NULL_")
                )
        )) AS calitp_hash,
        -- TODO: refactor to use ROW_NUMBER or RANK = 1 instead of MIN
        calitp_extracted_at = MIN(calitp_extracted_at)
        OVER (PARTITION BY itp_id, url_number)
        AS is_first_extraction
    FROM calitp_status
),

-- cross unique itp_id, url_number with dates we have for calitp_extracted_at
-- this will let us detect later on when an entry is missing (e.g. does not exist
-- for a certain date)
feed_id_cross_date AS (
    SELECT *
    FROM (SELECT DISTINCT
        itp_id,
        url_number
        FROM gtfs_schedule_feed_snapshot)
    CROSS JOIN (SELECT DISTINCT calitp_extracted_at FROM gtfs_schedule_feed_snapshot)
),

lag_md5_hash AS (
    SELECT
        *,
        LAG(calitp_hash)
        OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at)
        AS prev_calitp_hash,
        calitp_hash IS NULL
        AS is_removed
    FROM gtfs_schedule_feed_snapshot
    RIGHT JOIN feed_id_cross_date USING (itp_id, url_number, calitp_extracted_at)
),

    -- Determine whether file at next extraction has changed md5_hash
    -- use coalesce, so that if a file was added, it will be marked as changed

hash_check AS (
    SELECT
        *,
        calitp_hash != prev_calitp_hash OR is_first_extraction
        AS is_changed
    FROM lag_md5_hash
),

-- mark deleted at dates. note that this keeps removed entries so that their
-- created at dates can be used to mark deleted at for the previous entry.
feed_snapshot_with_removed AS (
    SELECT
        *,
        LEAD(calitp_extracted_at)
        OVER (PARTITION BY itp_id, url_number ORDER BY calitp_extracted_at)
        AS calitp_deleted_at

    FROM hash_check
    WHERE is_changed OR is_removed
),

final_data AS (
    SELECT
        TO_BASE64(MD5(
                CONCAT(calitp_hash, "__", CAST(T1.calitp_extracted_at AS STRING))
        ))
        AS feed_key,
        T1.itp_id AS calitp_itp_id,
        T1.url_number AS calitp_url_number,
        T1.agency_name AS calitp_agency_name,
        -- the version of URL without API key
        T2.gtfs_schedule_url AS raw_gtfs_schedule_url,
        T1.calitp_extracted_at,
        COALESCE(T1.calitp_deleted_at, "2099-01-01") AS calitp_deleted_at
    FROM feed_snapshot_with_removed AS T1
    LEFT JOIN safe_urls AS T2 USING (itp_id, url_number, calitp_extracted_at)
    WHERE NOT is_removed
),

exists_in_latest AS (
    SELECT
        calitp_itp_id,
        calitp_url_number,
        true AS calitp_id_in_latest
    FROM final_data
    WHERE calitp_deleted_at = "2099-01-01"
),

calitp_feeds AS (
    SELECT
        T1.*,
        COALESCE(T2.calitp_id_in_latest, false) AS calitp_id_in_latest,
        CONCAT(CAST(calitp_itp_id AS STRING), "__", CAST(calitp_url_number AS STRING)) AS calitp_feed_id,
        CONCAT(calitp_agency_name, " (", CAST(calitp_url_number AS STRING), ")") AS calitp_feed_name
    FROM final_data AS T1
    LEFT JOIN exists_in_latest AS T2 USING (calitp_itp_id, calitp_url_number)
)

SELECT * FROM calitp_feeds
