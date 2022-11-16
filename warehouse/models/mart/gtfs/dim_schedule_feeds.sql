{{ config(materialized='table') }}

WITH int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
),

hashed AS (
    SELECT
        base64_url,
        ts,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        CAST(download_success AS INTEGER) as int_download_success,
        {{ dbt_utils.surrogate_key(['gtfs_dataset_key', 'download_success', 'unzip_success',
         'zipfile_extract_md5hash']) }} AS content_hash
    FROM int_gtfs_schedule__joined_feed_outcomes
),

next_valid_extract AS (
    SELECT
        ts,
        LEAD(ts) OVER (ORDER BY ts) AS next_ts
    FROM hashed
    GROUP BY ts
    -- TODO: these are made up constants indicating "enough success to say that the downloader ran"
    HAVING ( (SUM(int_download_success) / COUNT(*)) > .9) AND (COUNT(*) >= 40)
),

latest_attempt_by_feed AS (
    SELECT
        base64_url,
        MAX(ts) AS latest_extract
    FROM hashed
    GROUP BY base64_url
),

in_latest AS (
    SELECT
        base64_url,
        latest_extract,
        (DENSE_RANK() OVER (ORDER BY latest_extract DESC)) = 1 AS in_latest,
        next_ts
    FROM latest_attempt_by_feed AS l
    LEFT JOIN next_valid_extract AS n
        ON l.latest_extract = n.ts
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        *,
        (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY ts) != content_hash)
            OR (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY ts) IS NULL) AS is_first
    FROM hashed
    WHERE download_success AND unzip_success IS NOT NULL
    QUALIFY is_first
),

versioned AS (
    SELECT
        f.base64_url,
        f.ts AS _valid_from,
        CASE
            -- if there's a subsequent extract, use that extract time as end date
            WHEN LEAD(f.ts) OVER (PARTITION BY f.base64_url ORDER BY f.ts) IS NOT NULL
                THEN {{ make_end_of_valid_range('LEAD(f.ts) OVER (PARTITION BY f.base64_url ORDER BY f.ts)') }}
            ELSE
            -- if there's no subsequent extract, it was either deleted or it's current
            -- if it was in the latest extract, call it current (even if it errored)
            -- if it was not in the latest extract, call it deleted at the last time it was extracted
                CASE
                    WHEN n.in_latest THEN {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }}
                    ELSE {{ make_end_of_valid_range('n.next_ts') }}
                END
        END AS _valid_to
    FROM first_instances AS f
    LEFT JOIN in_latest AS n
        ON f.base64_url = n.base64_url
),

dim_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['versioned.base64_url', 'versioned._valid_from']) }} AS key,
        versioned.base64_url,
        versioned._valid_from,
        versioned._valid_to
    FROM versioned
)

SELECT * FROM dim_schedule_feeds
