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
        AND download_success AND unzip_success
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
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        hashed.ts,
        base64_url,
        latest_extract,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        (DENSE_RANK() OVER (ORDER BY latest_extract DESC)) = 1 AS in_latest,
        next_ts,
        (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY hashed.ts) != content_hash)
            OR (LAG(content_hash) OVER (PARTITION BY base64_url ORDER BY hashed.ts) IS NULL) AS is_first
    FROM hashed
    LEFT JOIN next_valid_extract AS next
        ON hashed.latest_extract = next.ts
    QUALIFY is_first
),

all_versioned AS (
    SELECT
        base64_url,
        download_success,
        unzip_success,
        zipfile_extract_md5hash,
        ts AS _valid_from,
        CASE
            -- if there's a subsequent extract, use that extract time as end date
            WHEN LEAD(ts) OVER (PARTITION BY base64_url ORDER BY ts) IS NOT NULL
                THEN {{ make_end_of_valid_range('LEAD(ts) OVER (PARTITION BY base64_url ORDER BY ts)') }}
            ELSE
            -- if there's no subsequent extract, it was either deleted or it's current
            -- if it was in the latest extract, call it current (even if it errored)
            -- if it was not in the latest extract, call it deleted at the last time it was extracted
                CASE
                    WHEN in_latest THEN {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }}
                    ELSE {{ make_end_of_valid_range('next_ts') }}
                END
        END AS _valid_to
    FROM first_instances
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
    WHERE download_success AND unzip_success
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
