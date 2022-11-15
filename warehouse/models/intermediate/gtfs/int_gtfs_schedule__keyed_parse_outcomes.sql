WITH stg_gtfs_schedule__parse_outcomes AS (
    SELECT * FROM {{ ref('stg_gtfs_schedule__file_parse_outcomes') }}
),

dim_schedule_feeds AS (
    SELECT * FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__keyed_parse_outcomes AS (
    SELECT
        feeds.key AS feed_key,
        parse.parse_success,
        parse.parse_exception,
        parse.filename,
        parse._config_extract_ts,
        parse.feed_name,
        parse.feed_url,
        parse.original_filename,
        parse.fields,
        parse.gtfs_filename,
        parse.dt,
        parse.ts,
        parse.base64_url
    FROM stg_gtfs_schedule__parse_outcomes AS parse
    LEFT JOIN dim_schedule_feeds AS feeds
        ON parse.ts = feeds._valid_from
        AND parse.base64_url = feeds.base64_url
)

SELECT * FROM int_gtfs_schedule__keyed_parse_outcomes
