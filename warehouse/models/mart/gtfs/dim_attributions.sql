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
        TRUE AS warning_duplicate_primary_key,
    FROM make_dim
    GROUP BY base64_url, ts, attribution_id
    HAVING COUNT(*) > 1
),

dim_attributions AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', '_line_number']) }} AS key,
        feed_key,
        organization_name,
        make_dim.attribution_id,
        agency_id,
        route_id,
        trip_id,
        is_producer,
        is_operator,
        is_authority,
        attribution_url,
        attribution_email,
        attribution_phone,
        make_dim.base64_url,
        COALESCE(warning_duplicate_primary_key, FALSE) AS warning_duplicate_primary_key,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
    LEFT JOIN bad_rows
        ON make_dim.base64_url = bad_rows.base64_url
        AND make_dim.ts = bad_rows.ts
        AND make_dim.attribution_id = bad_rows.attribution_id
            OR (make_dim.attribution_id IS NULL AND bad_rows.attribution_id IS NULL)
)

SELECT * FROM dim_attributions
