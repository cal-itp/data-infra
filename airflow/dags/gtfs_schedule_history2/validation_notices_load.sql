---
operator: operators.SqlToWarehouseOperator
dst_table_name: "gtfs_schedule_type2.validation_notices"
external_dependencies:
  - gtfs_loader: gtfs_validation_history_load
---

WITH
# TODO: For some reason some of the extracted_at values are null, so we should
# investigate / re-run the processing in gtfs_loader. As a work around, this
# query parses the extraction date out of our file names.
fixed_extracted AS (
   SELECT
     * EXCEPT(calitp_extracted_at)
     , PARSE_DATE("%F", REGEXP_EXTRACT(_FILE_NAME, "processed/([0-9\\-]*)_.*/validation_report"))
         AS calitp_extracted_at
   FROM `gtfs_schedule_history.validation_report`
),
# adds a calitp_deleted_at column, similar to other tables in this DAG.
marked_deleted AS (
   SELECT
     *
     , LEAD(calitp_extracted_at)
         OVER (
          PARTITION BY
            calitp_itp_id,
            calitp_url_number
          ORDER BY
            calitp_extracted_at)
         AS calitp_deleted_at
   FROM fixed_extracted
),
# unnests so each row is an individual notice (e.g. a specific instance of
# a code violation. If there are two rows with invalid phone numbers, each
# will be a row here.)
unnested AS (
 SELECT
   calitp_itp_id
   , calitp_url_number
   , calitp_extracted_at
   , calitp_deleted_at
   , code.code AS code
   , code.severity AS severity
   , notices.*
 FROM
   marked_deleted AS t
   , UNNEST(t.notices) as code
   , UNNEST(code.notices) as notices
)
SELECT * FROM unnested
