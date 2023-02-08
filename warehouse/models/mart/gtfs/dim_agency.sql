WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__agency'),
    ) }}
),

dim_agency AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'agency_id']) }} AS key,
        feed_key,
        agency_id,
        agency_name,
        agency_url,
        agency_timezone,
        agency_lang,
        agency_phone,
        agency_fare_url,
        agency_email,
        base64_url,
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_agency
