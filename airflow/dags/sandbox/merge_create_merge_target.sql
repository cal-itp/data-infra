---
operator: operators.SqlQueryOperator
---

CREATE OR REPLACE TABLE `sandbox.merge_target` (
    calitp_itp_id INT64,
    calitp_url_number INT64,
    x INT64,
    calitp_extracted_at DATE,
    calitp_deleted_at DATE,
    calitp_hash STRING
)
