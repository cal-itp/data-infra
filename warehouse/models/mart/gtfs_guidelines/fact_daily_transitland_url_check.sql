WITH gtfs_fact_daily_transitland_url_check AS (
    SELECT

        dt,

        calitp_itp_id,

        -- suppressing because value is incorrect https://github.com/cal-itp/data-infra/issues/1825
        --calitp_url_number,

        url_type,

        transitland_status,

        transitland_public_web_url,

        url

    FROM {{ ref('stg_gtfs_guidelines__fact_daily_transitland_url_check') }}
)

SELECT * FROM gtfs_fact_daily_transitland_url_check
