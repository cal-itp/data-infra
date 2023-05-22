WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__fare_attributes'),
    ) }}
),

dim_fare_attributes AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['feed_key', 'fare_id']) }} AS key,
        feed_key,
        fare_id,
        price,
        currency_type,
        payment_method,
        transfers,
        agency_id,
        transfer_duration,
        base64_url,
        _dt,
        _feed_valid_from,
        _line_number,
        feed_timezone,
    FROM make_dim
)

SELECT * FROM dim_fare_attributes
