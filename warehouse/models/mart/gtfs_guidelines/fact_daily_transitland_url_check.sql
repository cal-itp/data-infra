WITH gtfs_fact_daily_transitland_url_check AS (
    SELECT *
    FROM {{ ref('stg_gtfs_guidelines__fact_daily_transitland_url_check') }}
)

SELECT * FROM gtfs_fact_daily_transitland_url_check
