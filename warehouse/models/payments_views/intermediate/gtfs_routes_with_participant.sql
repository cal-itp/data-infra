WITH gtfs_routes_with_participant AS (

    SELECT
        participant_id,
        route_id,
        route_short_name,
        route_long_name,
        calitp_extracted_at,
        calitp_deleted_at
    FROM {{ ref('gtfs_schedule_dim_routes') }}
    INNER JOIN {{ ref('payments_feeds') }} USING (calitp_itp_id, calitp_url_number)
)

SELECT * FROM gtfs_routes_with_participant
