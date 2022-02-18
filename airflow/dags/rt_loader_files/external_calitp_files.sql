---
operator: operators.SqlQueryOperator

dependencies:
  - calitp_files_process
---

CREATE OR REPLACE EXTERNAL TABLE `gtfs_rt.calitp_files` (
  calitp_itp_id INT64,
  calitp_url_number INT64,
  calitp_extracted_at DATETIME,
  name STRING,
  size INT64,
  md5_hash STRING,
)
OPTIONS (
    format = "CSV",
    uris = ["{{get_bucket()}}/rt-processed/calitp_files/*.csv"],
    skip_leading_rows = 1
)
