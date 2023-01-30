WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__attributions'),
    ) }}
),

bad_rows AS (
    SELECT
        base64_url,
        ts,
        attribution_id,
        TRUE AS warning_duplicate_primary_key
    FROM make_dim
    GROUP BY base64_url, ts, attribution_id
    HAVING COUNT(*) > 1
),

dim_attributions AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'attribution_id']) }} AS key,
        feed_key,
        organization_name,
        attribution_id,
        agency_id,
        route_id,
        trip_id,
        is_producer,
        is_operator,
        is_authority,
        attribution_url,
        attribution_email,
        attribution_phone,
        base64_url,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _feed_valid_from,
    FROM make_dim
    LEFT JOIN bad_rows
        USING (base64_url, ts, attribution_id)
)

SELECT * FROM dim_attributions
