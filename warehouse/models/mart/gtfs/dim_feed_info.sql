WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__feed_info'),
    ) }}
),

-- so we can reference twice
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['feed_publisher_name', 'feed_publisher_url', 'feed_lang', 'default_lang', 'feed_version', 'feed_contact_email', 'feed_contact_url', 'feed_start_date', 'feed_end_date']) }} AS feed_info_identifier,
    FROM make_dim
),

dim_feed_info AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'feed_info_identifier']) }} AS _gtfs_key,
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
        COUNT(*) OVER (PARTITION BY feed_key, feed_info_identifier) > 1 AS warning_duplicate_gtfs_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM with_identifier
)

SELECT * FROM dim_feed_info
