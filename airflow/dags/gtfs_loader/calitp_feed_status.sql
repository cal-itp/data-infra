---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_history.calitp_feed_status"

description: |
  Report the status of each feed in agencies.yml every day extraction was run
  across all time.

fields:
  calitp_itp_id: Internal feed itp id.
  calitp_url_number: Internal feed URL number.
  is_feed_updated: Whether the feed was updated (i.e. any loadable file was changed).
  is_extract_success: Whether the feed downloaded successfully.
  is_parse_error: |
    Whether the feed errored on parse. Note that the pipeline only attempts to parse
    updated feeds.
  crnt_is_feed_exists: Whether the feed exists in the latest agencies.yml file.
  is_latest_load: |
    Whether this is the latest feed data loaded. Note that latest feeds must have been
    extracted, parsed, and currently exist in agencies.yml.

dependencies:
  - gtfs_schedule_history_load
  - calitp_status_load
---

WITH

renamed_status AS (

    -- prefix calitp to internal id columns, for easy joining

    SELECT
        itp_id AS calitp_itp_id,
        url_number as calitp_url_number,
        calitp_extracted_at,
        status,
        calitp_extracted_at = MAX(calitp_extracted_at) OVER () AS is_latest
    FROM gtfs_schedule_history.calitp_status

),

current_feeds AS (

    -- the latest feeds in agencies.yml

    SELECT DISTINCT calitp_itp_id, calitp_url_number
    FROM renamed_status
    WHERE is_latest
),


feed_status AS (

    -- join in whether there was a parse error, and whether a feed was updated

    SELECT
        renamed_status.calitp_itp_id,
        renamed_status.calitp_url_number,
        renamed_status.calitp_extracted_at,
        renamed_status.status = "success"
            AS is_extract_success,

        -- detect whether there is an entry in calitp_feed_updates
        feed_updates.calitp_itp_id IS NOT NULL
            AS is_feed_updated,


        -- detect whether there is a True parse error in feed_parse_result
        COALESCE(feed_parse_result.parse_error_encountered, false)
            AS is_parse_error,

        -- detect whether feed currently exists (i.e. in agencies.yml)
        current_feeds.calitp_itp_id IS NOT NULL
            AS crnt_is_feed_exists

    FROM renamed_status
    LEFT JOIN gtfs_schedule_history.calitp_feed_updates AS feed_updates
        USING (calitp_itp_id, calitp_url_number, calitp_extracted_at)
    LEFT JOIN gtfs_schedule_history.calitp_feed_parse_result AS feed_parse_result
        USING (calitp_itp_id, calitp_url_number, calitp_extracted_at)
    LEFT JOIN current_feeds
        USING (calitp_itp_id, calitp_url_number)

),

feed_status_latest AS (

    -- calculate latest feed that was extracted, parsed, and exists in the current agencies.yml

    SELECT
        -- grouping cols
        calitp_itp_id,
        calitp_url_number,

        -- aggregates
        MAX(calitp_extracted_at) AS calitp_extracted_at,
        true AS is_latest_load
    FROM feed_status
    WHERE
        is_extract_success
        AND NOT is_parse_error
        AND crnt_is_feed_exists
        AND is_feed_updated
    GROUP BY 1, 2

)

SELECT
    feed_status.*,
    COALESCE(feed_status_latest.is_latest_load, false) AS is_latest_load
FROM feed_status
LEFT JOIN feed_status_latest
    USING (calitp_itp_id, calitp_url_number, calitp_extracted_at)
