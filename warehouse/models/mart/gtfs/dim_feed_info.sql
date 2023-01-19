{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

stg_gtfs_schedule__feed_info AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__feed_info') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'stg_gtfs_schedule__feed_info') }}
),

dim_feed_info AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'feed_publisher_name', 'feed_publisher_url', 'feed_lang', 'default_lang', 'feed_version', 'feed_contact_email', 'feed_contact_url', 'feed_start_date', 'feed_end_date']) }} AS key,
        feed_key,
        feed_publisher_name,
        feed_publisher_url,
        feed_lang,
        default_lang,
        feed_version,
        feed_contact_email,
        feed_contact_url,
        feed_start_date,
        feed_end_date,
        base64_url,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_feed_info
