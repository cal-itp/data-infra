WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__attributions'),
    ) }}
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
        _feed_valid_from,
    FROM make_dim
)

SELECT * FROM dim_attributions
