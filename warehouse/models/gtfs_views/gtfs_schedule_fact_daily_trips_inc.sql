{{
    config(
        materialized='incremental',
        unique_key=['feed_key', 'trip_key', 'service_date']
    )
}}

WITH gtfs_schedule_dim_feeds AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_feeds') }}
),

gtfs_schedule_dim_trips AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_trips') }}
),

gtfs_schedule_stg_daily_service AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_stg_daily_service') }}
),

gtfs_schedule_dim_stop_times AS (
    SELECT *
    FROM {{ ref('gtfs_schedule_dim_stop_times') }}
    {% if is_incremental() %}
        WHERE
            (calitp_extracted_at >= --noqa
                (SELECT MAX(calitp_extracted_at)
                    FROM {{ this }})
            )
            OR --noqa
            (calitp_deleted_at >= --noqa
                (SELECT MAX(calitp_deleted_at)
                    FROM {{ this }}
                    WHERE calitp_deleted_at != '2099-01-01')
            )
    {% endif %}
),
-- Each trip with scheduled service on a date, augmented with route_id, first departure,
-- and last arrival timestamps.

stg_daily_service_keyed AS (

    SELECT
        T2.feed_key,
        T1.*
    FROM gtfs_schedule_stg_daily_service AS T1
    INNER JOIN gtfs_schedule_dim_feeds AS T2
        ON
            T1.calitp_itp_id = T2.calitp_itp_id
            AND T1.calitp_url_number = T2.calitp_url_number
            AND T2.calitp_extracted_at <= T1.service_date
            AND T2.calitp_deleted_at > T1.service_date

),

daily_service_trips AS (
    -- Daily service for each trip. Note that scheduled service in the calendar
    -- can have multiple trips associated with it, via the service_id key.
    -- (i.e. calendar service to trips is 1-to-many)
    SELECT
        t1.feed_key,
        t2.trip_key,
        t2.trip_id,
        t2.route_id,
        t1.* EXCEPT (feed_key)
    FROM stg_daily_service_keyed AS t1
    INNER JOIN gtfs_schedule_dim_trips AS t2
        USING (calitp_itp_id, calitp_url_number, service_id)
    WHERE
        t2.calitp_extracted_at <= t1.service_date
        AND t2.calitp_deleted_at > t1.service_date
),

service_dates AS (
    -- Each unique value for service_date
    (SELECT DISTINCT service_date FROM gtfs_schedule_stg_daily_service)
),

trip_summary AS (
    -- Trip metrics for each possible service date (e.g. for a given trip that existed
    -- on this day, when was its last arrival? how many stops did it have?)
    SELECT
        t1.calitp_itp_id,
        t1.calitp_url_number,
        t1.trip_id,
        t2.service_date,
        COUNT(DISTINCT t1.stop_id) AS n_stops,
        COUNT(*) AS n_stop_times,
        MIN(t1.departure_ts) AS trip_first_departure_ts,
        MAX(t1.arrival_ts) AS trip_last_arrival_ts
    FROM gtfs_schedule_dim_stop_times AS t1
    INNER JOIN service_dates AS t2
        ON t1.calitp_extracted_at <= t2.service_date
            AND COALESCE(t1.calitp_deleted_at, DATE("2099-01-01")) > t2.service_date
    GROUP BY 1, 2, 3, 4
),

gtfs_schedule_fact_daily_trips AS (
    SELECT
        t1.*,
        t2.* EXCEPT(calitp_itp_id, calitp_url_number, trip_id, service_date),
        (t2.trip_last_arrival_ts - t2.trip_first_departure_ts) / 3600 AS service_hours
    FROM daily_service_trips AS t1
    INNER JOIN trip_summary AS t2
        USING (calitp_itp_id, calitp_url_number, trip_id, service_date)
)

SELECT * FROM gtfs_schedule_fact_daily_trips
