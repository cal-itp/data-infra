{{ config(materialized='table') }}

WITH int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
),

dim_gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
),

in_latest AS (
    SELECT
        base64_url,
        TRUE as in_latest
    FROM int_gtfs_schedule__joined_feed_outcomes
    QUALIFY DENSE_RANK() OVER (ORDER BY ts DESC) = 1
),

hashed AS (
    SELECT
        base64_url,
        ts,
        gtfs_dataset_key,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        CAST(download_success AS INTEGER) as int_download_success,
        {{ dbt_utils.surrogate_key(['gtfs_dataset_key', 'download_success', 'unzip_success',
         'zipfile_extract_md5hash']) }} AS content_hash
    FROM int_gtfs_schedule__joined_feed_outcomes
),

valid_global_extracts AS (
    SELECT
        ts,
        COUNT(*) AS ct,
        SUM(int_download_success) AS ct_successful
    FROM hashed
    GROUP BY ts
    -- TODO: these are made up constants
    HAVING (ct / ct_successful > .9) AND (ct >= 40)
),

next_valid_extract AS (
    SELECT
        ts,
        LEAD(ts) OVER (ORDER BY ts) AS next_ts
    FROM valid_global_extracts
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        *,
        (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY ts) != content_hash)
            OR (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY ts) IS NULL) AS is_first
    FROM hashed
    QUALIFY is_first
),

versioned AS (
    SELECT
        f.base64_url,
        f.gtfs_dataset_key,
        f.ts AS _valid_from,
        -- if there's a subsequent extract, use that extract time as end date
        -- if there's no subsequent extract, it was either deleted or it's current
        -- check if there was another global extract; it so, use that as end date
        -- if no subsequent global extract, assume current
        {{ make_end_of_valid_range(
            'COALESCE(
                LEAD(f.ts) OVER (PARTITION BY f.base64_url ORDER BY f.ts),
                n.next_ts,
                CAST("2099-01-01" AS TIMESTAMP)
            )')
        }} AS _valid_to
    FROM first_instances AS f
    LEFT JOIN next_valid_extract AS n
        ON f.ts = n.ts
),

dim_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['versioned.base64_url', 'versioned._valid_from']) }} AS key,
        versioned.base64_url,
        versioned.gtfs_dataset_key,
        gd.name,
        versioned._valid_from,
        versioned._valid_to
    FROM versioned
    LEFT JOIN dim_gtfs_datasets AS gd
        on gtfs_dataset_key = gd.key
)

SELECT * FROM dim_schedule_feeds
