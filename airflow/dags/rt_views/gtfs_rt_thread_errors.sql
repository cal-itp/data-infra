---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.gtfs_rt_thread_errors"

description: | Each row is a unique file_hash of a feed that generated an exception within GCP logger


fields:
  file_hash: unique identifier for each feed download attempt.
  calitp_itp_id: Feed ITP ID.
  calitp_url_number: Feed URL number.
  feed_file: Combination calitp_itp_id, URL number, and feed URL name.
  feed_file_name: feed url name.
  start_fetch_time: timestamp of start_fetch thread as logged by archiver.
  completed_fetch_time: timestamp of completed_fetch thread as logged by archiver.
  start_write_time: timestamp of start_write thread as logged by archiver.
  completed_write_time: timestamp of completed_write thread as logged by archiver.
  error_time: timestamp when thread exception occured.
  error_message: error message contained within the exception.
---

-- note that archiver will log a completed write time regardless if fetch was successful due to them being on separate threads
-- this will be changed in future iterations

With
start_fetch AS (
    SELECT
        textpayload,
        timestamp AS start_fetch_time,
        REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS file_hash,
        REGEXP_EXTRACT(textPayload, "mapper_key=([0-9]+)")AS calitp_itp_id,
        REGEXP_EXTRACT(textPayload, "mapper_key=[0-9]+/([0-9]+)")AS calitp_url_number,
        REGEXP_EXTRACT(textpayload,"mapper_key=[0-9]+/[0-9]+/?([a-zA-Z0-9\\.\\_\\-]+)?") AS feed_file_name,
        REGEXP_EXTRACT(textpayload,"mapper_key=([0-9]+/[0-9]+/?[a-zA-Z0-9\\.\\_\\-]+)?") AS feed_file,

    FROM `cal-itp-data-infra.gtfs_rt_logs.stdout`
    WHERE textPayload like "%start fetch%"
),
complete_fetch AS (
    SELECT
        timestamp as completed_fetch_time,
        REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS c_file_hash,
    FROM `cal-itp-data-infra.gtfs_rt_logs.stdout`
    WHERE textPayload like "%completed fetch%"
),
fetch_join_table AS (
    SELECT * FROM start_fetch t1
    JOIN complete_fetch t2  ON t1.file_hash = t2.c_file_hash
),
start_write AS (
    SELECT
        textpayload,
        timestamp AS start_write_time,
        REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS file_hash,
    FROM `cal-itp-data-infra.gtfs_rt_logs.stdout`
    WHERE textPayload like "%start write%"
),
complete_write AS (
    SELECT
        timestamp AS completed_write_time,
        REGEXP_EXTRACT(textPayload, r'\[txn (.*?)\]') AS c_file_hash,
    FROM `cal-itp-data-infra.gtfs_rt_logs.stdout`
    WHERE textPayload like "%completed write%"
),
write_join_table AS (
    SELECT * FROM start_write t3
    JOIN complete_write t4  ON t3.file_hash = t4.c_file_hash
),
log_table AS (
    SELECT
t1. file_hash,
t1.calitp_itp_id,
t1.calitp_url_number,
t1.feed_file,
t1. start_fetch_time,
t1.completed_fetch_time,
t2.start_write_time,
t2.completed_write_time,
 FROM fetch_join_table t1 JOIN write_join_table t2 ON t1.file_hash = t2.file_hash
),
stderr_table AS (
    SELECT textPayload, timestamp AS error_time,
    REGEXP_EXTRACT(textpayload,"fetcher ([0-9]+/[0-9]+/?[a-zA-Z0-9\\.\\_\\-]+)?") AS feed_file,
    FROM `cal-itp-data-infra.gtfs_rt_logs.stderr`
    WHERE textPayload LIKE "%fetcher%"
)
SELECT
t1. file_hash,
t1.calitp_itp_id,
t1.calitp_url_number,
t1.feed_file,
t1. start_fetch_time,
t1.completed_fetch_time,
t1. start_write_time,
t1.completed_write_time,
t2.error_time,
t2.textpayload AS error_message
FROM log_table t1
JOIN stderr_table t2 ON t1.feed_file = t2.feed_file
AND t2.error_time >= t1.start_fetch_time AND t2.error_time < t1.completed_write_time
