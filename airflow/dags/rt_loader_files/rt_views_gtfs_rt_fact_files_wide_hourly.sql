---
operator: operators.SqlToWarehouseOperator
# write to views even though this is not in views DAG so we can run more often if needed
dst_table_name: "views.gtfs_rt_fact_files_wide_hourly"

description: |
  Each row is one day of realtime data for a given feed (ITP ID + URL number + realtime type),
  with count of files downloaded by hour.
  Note that presence of a file is not a guarantee that the downloaded file is complete or valid.


fields:
  date_extracted: Date extracted from calitp_extracted_at
  calitp_itp_id: Feed ITP ID
  calitp_url_number: Feed URL number
  name: File type (service_alerts, trip_updates, or vehicle_positions)
  file_count_0: Count of files extracted during hour 0 UTC

dependencies:
  - rt_views_gtfs_rt_fact_files
---

SELECT *
FROM
    (SELECT
        date_extracted,
        calitp_itp_id,
        calitp_url_number,
        name,
        calitp_extracted_at,
        hour_extracted
    FROM `views.gtfs_rt_fact_files`)
PIVOT(
    count(calitp_extracted_at) file_count_hr
    FOR hour_extracted in
        (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
         11, 12, 13, 14, 15, 16, 17, 18, 19,
         20, 21, 22, 23)
    )
