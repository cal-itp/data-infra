{{ config(materialized='table') }}

WITH calitp_status AS (
    SELECT *
    FROM {{ source('gtfs_schedule_history', 'calitp_status') }}
),

dim_date AS (
    SELECT *
    FROM {{ ref('dim_date') }}
),

feed_info_clean AS (
    SELECT *
    FROM {{ ref('feed_info_clean') }}
),


publish_dates AS (
    SELECT
        full_date AS date_start,
        LAST_DAY(full_date, MONTH) AS date_end,
        DATE_ADD(LAST_DAY(full_date, MONTH), INTERVAL 1 DAY) AS publish_date
    FROM dim_date
    WHERE
        DATE_TRUNC(full_date, MONTH) = full_date
),

publish_dates_crnt AS (
    SELECT * FROM publish_dates
    WHERE publish_date BETWEEN "2021-06-01" AND CURRENT_DATE()
),

-- For each publish_date above, check which gtfs data sets have a feed_info
-- file in them. Currently, reports will error if this file is missing.
has_feed_info_end_date AS (
    SELECT DISTINCT
        PD.publish_date,
        calitp_itp_id,
        calitp_url_number,
        TRUE AS has_feed_info
    FROM feed_info_clean AS FI
    INNER JOIN publish_dates_crnt AS PD ON
        FI.calitp_extracted_at <= PD.date_end
        AND COALESCE(FI.calitp_deleted_at, "2099-01-01") > PD.date_end
),

-- For each publish date, get the agencies listed in agencies.yml
-- on that date. These will be used to generate the reports for that
-- month. Critically this will not change over time (whereas using the
-- most recent agencies.yml file data would).
agency_feeds_on_end_date AS (
    SELECT
        PD.publish_date,
        S.itp_id AS calitp_itp_id,
        S.url_number AS calitp_url_number,
        S.agency_name,
        COALESCE(FI.has_feed_info, FALSE)
        AS has_feed_info,
        -- Hardcode certain feeds as private to make sure reports are not generated
        S.itp_id IN (13, 346) AS is_private_feed
    FROM calitp_status AS S
    INNER JOIN publish_dates_crnt AS PD ON
        S.calitp_extracted_at = PD.date_end
    LEFT JOIN has_feed_info_end_date AS FI
        ON S.itp_id = FI.calitp_itp_id
            AND S.url_number = FI.calitp_url_number
            AND PD.publish_date = FI.publish_date
),

reports_gtfs_schedule_index AS (
    SELECT
        publish_date,
        calitp_itp_id,
        calitp_url_number,
        AF.agency_name,
        PD.date_start,
        PD.date_end,
        has_feed_info,
        is_private_feed,
        (calitp_url_number = 0
            -- try making optional for June reports
            -- AND has_feed_info
            AND NOT is_private_feed
        ) AS use_for_report
    FROM agency_feeds_on_end_date AS AF
    INNER JOIN publish_dates_crnt AS PD
        USING (publish_date)
)

SELECT * FROM reports_gtfs_schedule_index
