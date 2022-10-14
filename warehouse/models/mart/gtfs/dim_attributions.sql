{{ config(materialized='table') }}

WITH dim_schedule_feeds AS (
    SELECT *
    FROM {{ ref('dim_schedule_feeds') }}
),

int_gtfs_schedule__deduped_attributions AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__deduped_attributions') }}
),

make_dim AS (
{{ make_schedule_file_dimension_from_dim_schedule_feeds('dim_schedule_feeds', 'int_gtfs_schedule__deduped_attributions') }}
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
        _valid_from,
        _valid_to
    FROM make_dim
)

SELECT * FROM dim_attributions
