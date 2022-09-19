WITH gtfs_fact_daily_transitland_url_check AS (
    SELECT

        dt,

        calitp_itp_id,

        calitp_url_number,

        url_type,

        transitland_status,

        transitland_public_web_url,

        url

    FROM {{ ref('stg_gtfs_guidelines__fact_daily_transitland_url_check') }}
)

SELECT * FROM gtfs_fact_daily_transitland_url_check
