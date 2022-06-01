{{ config(materialized='table') }}

WITH calitp_status AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_status') }}
),

calitp_feed_parse_result AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_feed_parse_result') }}
),

calitp_feeds_raw AS (
    SELECT
        *,
        _FILE_NAME
    FROM {{ source('gtfs_schedule_history', 'calitp_feeds_raw') }}
),

calitp_feed_updates AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_feed_updates') }}
),

gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

gtfs_schedule_service AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_fact_daily_service') }}
),

dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
)


-- create underlying dimensions: daily feeds

daily_feeds AS (
    SELECT
        Feeds.feed_key,
        D.full_date AS date,

        -- is the feed valid on this date?
        (Feeds.feed_start_date <= full_date AND Feeds.feed_end_date >= full_date)
        AS is_feed_publish_date_valid,

        -- how long until this feed ends?
        DATE_DIFF(Feeds.feed_end_date, D.full_date, DAY)
        AS days_until_feed_end_date,

        -- how long ago did this feed start?
        DATE_DIFF(D.full_date, Feeds.feed_start_date, DAY)
        AS days_from_feed_start_date,

        calitp_itp_id,
        calitp_url_number

    FROM gtfs_schedule_dim_feeds AS Feeds
    INNER JOIN dim_date AS D
        ON
            Feeds.calitp_extracted_at <= D.full_date
            AND Feeds.calitp_deleted_at > D.full_date
            AND D.is_in_past_or_present
),

daily_service AS (
    SELECT
        gtfs_schedule_service.feed_key,
        MAX(gtfs_schedule_service.service_date) AS max_service_date,
        MIN(gtfs_schedule_service.service_date) AS min_service_date,


    FROM gtfs_schedule_service
    GROUP BY gtfs_schedule_service.feed_key

),

-- join daily_service with daily_feeds to get days until service end and days from service start

daily_feed_join AS (
    SELECT
        daily_feeds.*,

        -- is the service valid on this date?
        (daily_service.min_service_date <= daily_feeds.date AND daily_service.max_service_date >= daily_feeds.date)
        AS is_service_date_valid,

          -- how long until this service ends?
        DATE_DIFF(daily_service.max_service_date, daily_feeds.date, DAY)
        AS days_until_service_end_date,


        -- how long ago did this service start?
        DATE_DIFF(daily_feeds.date, daily_service.min_service_date, DAY)
        AS days_from_service_start_date

    FROM daily_feeds
    LEFT JOIN daily_service USING (feed_key)
),



-- Extract raw feeds URLs

raw_feed_urls AS (
    SELECT
        *,
        PARSE_DATE(
            '%Y-%m-%d',
            REGEXP_EXTRACT(_FILE_NAME, ".*/([0-9]+-[0-9]+-[0-9]+)")
        ) AS extract_date
    FROM calitp_feeds_raw
),


-- join in whether or not a feed download succeeded on a given day and also the raw feed
    -- URLs

feed_status AS (
    SELECT
        daily_feed_join.*,
        CASE WHEN download_status.status = "success" THEN "success" ELSE "error"
        END
        AS extraction_status,
        parse_result.parse_error_encountered,
        raw_feed_urls.gtfs_schedule_url AS raw_gtfs_schedule_url,
        raw_feed_urls.gtfs_rt_vehicle_positions_url AS raw_gtfs_rt_vehicle_positions_url,
        raw_feed_urls.gtfs_rt_service_alerts_url AS raw_gtfs_rt_service_alerts_url,
        raw_feed_urls.gtfs_rt_trip_updates_url AS raw_gtfs_rt_trip_updates_url
    FROM daily_feed_join
    LEFT JOIN calitp_status AS download_status
        ON
            daily_feed_join.calitp_itp_id = download_status.itp_id
            AND daily_feed_join.calitp_url_number = download_status.url_number
            AND daily_feed_join.date = download_status.calitp_extracted_at
    LEFT JOIN calitp_feed_parse_result AS parse_result
        ON
            daily_feed_join.calitp_itp_id = parse_result.calitp_itp_id
            AND daily_feed_join.calitp_url_number = parse_result.calitp_url_number
            AND daily_feed_join.date = parse_result.calitp_extracted_at
    LEFT JOIN raw_feed_urls
        ON
            daily_feed_join.calitp_itp_id = raw_feed_urls.itp_id
            AND daily_feed_join.calitp_url_number = raw_feed_urls.url_number
            AND daily_feed_join.date = raw_feed_urls.extract_date
),

-- join in whether or not a feed updated on this day

feed_updated AS (

    SELECT
        T1.*,
        -- Calculate days since update, by forward filling extracted at
        DATE_DIFF(
            T1.date,
            LAST_VALUE(T2.calitp_extracted_at IGNORE NULLS)
            OVER (PARTITION BY T1.calitp_itp_id, T1.calitp_url_number ORDER BY T1.date),
            DAY

        ) AS days_from_last_schedule_update
    FROM feed_status AS T1
    LEFT JOIN calitp_feed_updates AS T2
        ON
            T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T1.date = T2.calitp_extracted_at

),

gtfs_schedule_fact_daily_feeds AS (
    SELECT
        * EXCEPT(calitp_itp_id, calitp_url_number)
    FROM feed_updated
)

SELECT * FROM gtfs_schedule_fact_daily_feeds
