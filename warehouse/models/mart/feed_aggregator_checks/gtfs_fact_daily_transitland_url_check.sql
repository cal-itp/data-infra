WITH gtfs_fact_daily_transitland_url_check AS (
    SELECT *
    FROM {{ ref('stg_feed_aggregator_checks__gtfs_fact_daily_transitland_url_check') }}
)

SELECT * FROM gtfs_fact_daily_transitland_url_check
