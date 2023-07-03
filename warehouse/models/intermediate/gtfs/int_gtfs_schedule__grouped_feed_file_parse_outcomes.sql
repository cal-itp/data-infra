WITH stg_gtfs_schedule__file_parse_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__file_parse_outcomes') }}
),

make_numeric AS (
    SELECT
        base64_url,
        dt,
        ts,
        CAST(parse_success AS INTEGER) AS int_success
    FROM stg_gtfs_schedule__file_parse_outcomes
),

summarize AS (
    SELECT
        base64_url,
        dt,
        ts,
        SUM(int_success) AS count_successes,
        COUNT(*) AS count_files
    FROM make_numeric
    GROUP BY base64_url, dt, ts
),

int_gtfs_schedule__grouped_feed_file_parse_outcomes AS (
    SELECT
        base64_url,
        dt,
        ts,
        count_successes,
        count_files,
        (count_successes / count_files) * 100 AS pct_success
    FROM summarize
)

SELECT * FROM int_gtfs_schedule__grouped_feed_file_parse_outcomes
