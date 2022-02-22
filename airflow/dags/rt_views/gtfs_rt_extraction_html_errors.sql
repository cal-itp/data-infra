---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_rt_extraction_html_errors"

description: |
  Each row is a unique text payload returned for a HTTP Error for the calitp RT_archiver

fields:
  calitp_itp_id: Feed ITP ID.
  calitp_url_number: Feed URL number.
  textPayload: Error message that contains feed key, header length, download url, and error response.
  download_url: Feed url extracted from textPayload.
  http_error: Extracted HTTP error code.
  n_count: Count of each row, distinct text textPayload.
  max_date: Max timestamp.

---

WITH

  start_fetch_table AS (
  SELECT
    REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS file_hash,
    REGEXP_EXTRACT(textPayload, "mapper_key=([0-9]+)")AS calitp_itp_id,
    REGEXP_EXTRACT(textPayload, "mapper_key=[0-9]+/([0-9]+)")AS calitp_url_number,
  FROM
    `cal-itp-data-infra.gtfs_rt_logs.stdout`
  WHERE
    textPayload LIKE "%start fetch%"
    ),

  error_fetch_table AS (
  SELECT
    textPayload,
    timestamp,
    REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS file_hash,
    REGEXP_EXTRACT(textpayload,r'error fetching url ([a-zA-Z].*)?=') AS download_url,
    --- trim API tokens because sensitive info
    REGEXP_EXTRACT(textpayload,"(HTTP Error [0-9]+.*)") AS http_error,
  FROM
    `cal-itp-data-infra.gtfs_rt_logs.stdout`
  WHERE
    textPayload LIKE "%error fetching %"
    ),
--- have to join the two tables as the textPayload that is returned upon HTTP error does not contain the calitp_id and url number
  join_table AS (
  SELECT
    *
  FROM
    start_fetch_table t1
  JOIN
    error_fetch_table t2
  ON
    t1.file_hash = t2.file_hash
  ORDER BY
    calitp_itp_id DESC )

SELECT
  calitp_itp_id,
  calitp_url_number,
  textPayload,
  download_url,
  http_error,
  COUNT(*) AS n_count,
  MAX(timestamp) AS max_date
FROM
  join_table
WHERE
  timestamp >= (datetime_sub(CURRENT_TIMESTAMP(),
      INTERVAL 28 day))
  AND http_error IS NOT NULL
GROUP BY
  1,
  2,
  3,
  4,
  5
ORDER BY
  max_date DESC
