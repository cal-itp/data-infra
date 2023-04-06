{{ config(materialized='table') }}

{%- set timestamps = dbt_utils.get_column_values(
        table = ref('int_gtfs_schedule__joined_feed_outcomes'),
        column = 'ts',
        order_by = 'ts DESC',
        where = 'unzip_success IS NOT NULL') -%}
{%- set latest_processed_timestamp = timestamps[0] -%}

WITH int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
    WHERE EXTRACT(DATE FROM ts) <= EXTRACT(DATE FROM TIMESTAMP '{{ latest_processed_timestamp }}')
),

agencies AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__agency') }}
),

data_available AS (
    SELECT *
    FROM int_gtfs_schedule__joined_feed_outcomes
    WHERE download_success AND unzip_success
),

hashed AS (
    SELECT
        base64_url,
        ts,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        CAST(download_success AS INTEGER) as int_download_success,
        MAX(ts) OVER(PARTITION BY base64_url ORDER BY ts DESC) AS latest_extract,
        {{ dbt_utils.generate_surrogate_key(['download_success', 'unzip_success',
         'zipfile_extract_md5hash']) }} AS content_hash
    FROM data_available
),

next_valid_extract AS (
    SELECT
        ts,
        LEAD(ts) OVER (ORDER BY ts) AS next_ts
    FROM hashed
    GROUP BY ts
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        hashed.ts,
        base64_url,
        latest_extract,
        download_success,
        unzip_success,
        content_hash,
        zipfile_extract_md5hash,
        (DENSE_RANK() OVER (ORDER BY latest_extract DESC)) = 1 AS in_latest,
        next_ts,
        LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY hashed.ts) != content_hash AS continuous_first,
        LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY hashed.ts) IS NULL AS discontinuous_first
    FROM hashed
    LEFT JOIN next_valid_extract AS next_global
        ON hashed.latest_extract = next_global.ts
    QUALIFY continuous_first OR discontinuous_first
),

-- because URLs can be deleted from our list but then reoccur
-- (which is nonstandard for keys in this kind of SCD logic)
-- we need to add specific checks to figure out whether the URL was deleted between instances
-- first step: find what our consecutive versions are
get_next_first AS (
    SELECT
        base64_url,
        download_success,
        unzip_success,
        content_hash,
        zipfile_extract_md5hash,
        ts,
        LEAD(ts) OVER(PARTITION BY base64_url ORDER BY ts) AS next_first_ts
    FROM first_instances
),

-- now fill in all observed successes between the versions
all_versioned AS (
    SELECT
        get_next_first.base64_url,
        get_next_first.download_success,
        get_next_first.unzip_success,
        get_next_first.content_hash,
        get_next_first.zipfile_extract_md5hash,
        get_next_first.ts AS _valid_from,
        {{ make_end_of_valid_range('COALESCE(
                (
                -- this is the first (global) extract after the last successful instance of the current version
                LAST_VALUE(next_valid_extract.next_ts)
                    OVER(PARTITION BY get_next_first.base64_url, get_next_first.ts
                        ORDER BY data_available.ts
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                ),
                "2099-01-01"
        )') }} AS _valid_to
    FROM get_next_first
    LEFT JOIN data_available
        ON get_next_first.base64_url = data_available.base64_url
        AND data_available.ts BETWEEN get_next_first.ts AND {{ make_end_of_valid_range('COALESCE(get_next_first.next_first_ts, "2099-01-01")') }}
    LEFT JOIN next_valid_extract
        ON data_available.ts = next_valid_extract.ts
    -- filter to only the last successful appearance of the current version
    QUALIFY data_available.ts =  LAST_VALUE(data_available.ts) OVER(PARTITION BY get_next_first.base64_url, get_next_first.ts ORDER BY data_available.ts ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
),

actual_data_only AS (
    SELECT
        base64_url,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        _valid_from,
        _valid_to,
        _valid_to = {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _is_current
    FROM all_versioned
),

-- make sure we get only one time zone per feed
-- per spec there should only be one but this guarantees it
get_feed_time_zone AS (
    SELECT
        ts,
        base64_url,
        agency_timezone AS feed_timezone,
        COUNT(*) AS ct
    FROM agencies
    -- SQLFluff doesn't like number column references here with column names in window function
    GROUP BY 1, 2, 3, 4 --noqa: AM06
    QUALIFY RANK() OVER (PARTITION BY ts, base64_url ORDER BY ct DESC, agency_timezone_valid_tz ASC) = 1
),

dim_schedule_feeds AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['actual_data_only.base64_url', '_valid_from']) }} AS key,
        actual_data_only.base64_url,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        feed_timezone,
        _valid_from,
        _valid_to,
        _is_current
    FROM actual_data_only
    LEFT JOIN get_feed_time_zone
        ON actual_data_only._valid_from = get_feed_time_zone.ts
        AND actual_data_only.base64_url = get_feed_time_zone.base64_url
)

SELECT * FROM dim_schedule_feeds
