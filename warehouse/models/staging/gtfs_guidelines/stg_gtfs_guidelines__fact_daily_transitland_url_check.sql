{{ config(materialized='table') }}

WITH gtfs_fact_daily_transitland_url_check AS (
    SELECT

        dt,

        itp_id AS calitp_itp_id,

        url_number AS calitp_url_number,

        url_type,

        transitland.status AS transitland_status,

        transitland.public_web_url AS transitland_public_web_url,

        url

    FROM {{ source('feed_aggregator_checks', 'feed_checks') }}
)

SELECT * FROM gtfs_fact_daily_transitland_url_check
