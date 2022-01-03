---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_rt_extraction_errors"

description: |
Each row is a unique error message of a feed that failed to fetch the feed url used in agency.yml


fields:
  textPayload: error message that contains error severity, calitp id, Feed URL number, and feed file name that generated error
  timestamp: time and date of when error message was received,
  calitp_itp_id: Feed ITP ID.
  calitp_url_number: Feed URL number.
---

WITH
download_issues AS (
    SELECT
        textPayload,
        timestamp,
        CAST(
            REGEXP_EXTRACT(textPayload, "INFO:/gtfs-rt-archive.py:fetcher ([0-9]+)")
            AS INT
        ) AS calitp_itp_id,
        CAST(
            REGEXP_EXTRACT(textPayload, "INFO:/gtfs-rt-archive.py:fetcher [0-9]+/([0-9]+)")
            AS INT
        ) AS calitp_url_number
    -- note that we've moved the logs to gtfs_rt_logs.stdout, since the table name can't be changed
    -- but using this table for now, since it holds full data for Dec 14th
    FROM `cal-itp-data-infra.gtfs_rt.stdout`
    WHERE textPayload LIKE "%error fetching url%"
)

SELECT * FROM download_issues
