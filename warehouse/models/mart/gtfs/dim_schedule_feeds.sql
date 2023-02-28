{{ config(materialized='table') }}

-- TODO: when we have dbt-utils version 0.8.5 or higher, could just use get_column_values with a where clause
-- we can have a lag where download success is populated but unzip success is not
{% set get_max_ts_sql %}
    SELECT MAX(ts) AS max_ts
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
    WHERE unzip_success IS NOT NULL
{% endset %}

{%- set timestamps = dbt_utils.get_query_results_as_dict(get_max_ts_sql) -%}
{%- set latest_processed_timestamp = timestamps['max_ts'][0] -%}

WITH int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__joined_feed_outcomes') }}
    WHERE EXTRACT(DATE FROM ts) <= EXTRACT(DATE FROM TIMESTAMP '{{ latest_processed_timestamp }}')
),

successful_downloads AS (
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
        {{ dbt_utils.surrogate_key(['download_success', 'unzip_success',
         'zipfile_extract_md5hash']) }} AS content_hash
    FROM successful_downloads
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

all_versioned AS (
    SELECT
        get_next_first.base64_url,
        get_next_first.download_success,
        get_next_first.unzip_success,
        get_next_first.content_hash,
        get_next_first.zipfile_extract_md5hash,
        get_next_first.ts AS _valid_from,
        COALESCE(
                (
                -- this is the first (global) extract after the last successful instance of the current version
                LAST_VALUE(next_valid_extract.next_ts)
                    OVER(PARTITION BY get_next_first.base64_url, get_next_first.ts
                        ORDER BY successful_downloads.ts
                        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
                ),
                "2099-01-01")
            AS _valid_to_raw
    FROM get_next_first
    LEFT JOIN successful_downloads
        ON get_next_first.base64_url = successful_downloads.base64_url
        AND successful_downloads.ts BETWEEN get_next_first.ts AND {{ make_end_of_valid_range(COALESCE(get_next_first.next_first_ts, "2099-01-01")) }}
    LEFT JOIN next_valid_extract
        ON successful_downloads.ts = next_valid_extract.ts
    -- filter to only the last successful appearance of the current version
    QUALIFY successful_downloads.ts =  LAST_VALUE(successful_downloads.ts) OVER(PARTITION BY get_next_first.base64_url, get_next_first.ts ORDER BY successful_downloads.ts ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
),

actual_data_only AS (
    SELECT
        base64_url,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        _valid_from,
        {{ make_end_of_valid_range(_valid_to_raw) }} AS _valid_to,
        _valid_to = {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _is_current
    FROM all_versioned
),

dim_schedule_feeds AS (
    SELECT
        {{ dbt_utils.surrogate_key(['base64_url', '_valid_from']) }} AS key,
        base64_url,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        _valid_from,
        _valid_to,
        _is_current
    FROM actual_data_only
)

SELECT * FROM dim_schedule_feeds
