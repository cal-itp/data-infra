---
operator: operators.SqlToWarehouseOperator
# write to views even though this is not in views DAG so we can run more often if needed
dst_table_name: "views.gtfs_rt_fact_files"

description: |
  Each row is a GTFS realtime file that was downloaded.
  Note that presence of a file is not a guarantee that the downloaded file is complete or valid.


fields:
  calitp_extracted_at: Timestamp when this file was extracted
  calitp_itp_id: Feed ITP ID
  calitp_url_number: Feed URL number
  name: File type (service_alerts, trip_updates, or vehicle_positions)
  size: File size in bytes
  md5_hash: Hash of file contents
  date_extracted: Date extracted from calitp_extracted_at
  hour_extracted: Hour extracted from calitp_extracted_at
  minute_extracted: Minute extracted from calitp_extracted_at

dependencies:
  - external_calitp_files
---

SELECT
  calitp_extracted_at,
  calitp_itp_id,
  calitp_url_number,
  -- turn name from a file path like gtfs_rt_<file_type>_url
  -- to just file_type
  REGEXP_EXTRACT(name, r"gtfs_rt_(.*)_url") as name,
  size,
  md5_hash,
  DATE(calitp_extracted_at) as date_extracted,
  EXTRACT(HOUR from calitp_extracted_at) as hour_extracted,
  EXTRACT(MINUTE from calitp_extracted_at) as minute_extracted
FROM `gtfs_rt.calitp_files`
