WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__feed_info'),
    ) }}
),

-- typical pattern for letting us join on nulls
with_identifier AS (
    SELECT *, {{ dbt_utils.generate_surrogate_key(['feed_publisher_name', 'feed_publisher_url', 'feed_lang', 'default_lang', 'feed_version', 'feed_contact_email', 'feed_contact_url', 'feed_start_date', 'feed_end_date']) }} AS feed_info_identifier,
    FROM make_dim
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        {{ dbt_utils.generate_surrogate_key(['feed_publisher_name', 'feed_publisher_url', 'feed_lang', 'default_lang', 'feed_version', 'feed_contact_email', 'feed_contact_url', 'feed_start_date', 'feed_end_date']) }} AS feed_info_identifier,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY 1, 2, 3
    HAVING COUNT(*) > 1
),

dim_feed_info AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'feed_publisher_name', 'feed_publisher_url', 'feed_lang', 'default_lang', 'feed_version', 'feed_contact_email', 'feed_contact_url', 'feed_start_date', 'feed_end_date']) }} AS key,
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
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
        feed_timezone,
    FROM with_identifier
    LEFT JOIN bad_rows
        USING (base64_url, ts, feed_info_identifier)
)

SELECT * FROM dim_feed_info
